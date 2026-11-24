import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aspal/core/database/app_database.dart';
import 'package:aspal/features/auth/domain/repositories/token_provider.dart';
import 'package:aspal/features/reports/data/report_local_data_source.dart';
import 'package:aspal/features/reports/data/report_local_data_gateway.dart';
import 'package:aspal/features/reports/data/report_repository_impl.dart';
import 'package:aspal/features/reports/domain/models/report.dart';
import 'package:aspal/features/reports/domain/models/sync_status.dart';
import 'package:aspal/features/reports/domain/repositories/report_repository.dart';
import 'package:aspal/features/reports/presentation/report_presentation.dart';
import 'package:aspal/features/reports/presentation/report_location_map.dart';
import 'package:aspal/features/reports/report_form_service.dart';
import 'package:aspal/screens/my_report_history.dart';
import 'package:aspal/screens/my_report_detail.dart';
import 'package:aspal/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Account extends Fake implements TokenProvider {
  String? id = 'A';
  @override
  Future<String?> getUserId() async => id;
}

class _MemoryTiles extends TileProvider {
  final image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
    ),
  );
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      image;
}

// Keep native file/database I/O on the real event loop in widget tests.
class _WidgetRepository extends Fake implements ReportRepository {
  _WidgetRepository(this.repo, this.io);
  final ReportRepository repo;
  final Zone io;
  Future<void> pending = Future.value();
  Future<T> _run<T>(Future<T> Function() read) {
    final result = Completer<T>();
    pending = io.run(
      () => read().then<void>(result.complete, onError: result.completeError),
    );
    return result.future;
  }

  @override
  Future<List<Report>> getReportsByUser() => _run(repo.getReportsByUser);
  @override
  Future<List<Report>> getReportsByStatus(SyncStatus status) =>
      _run(() => repo.getReportsByStatus(status));
  @override
  Future<Report?> getReportById(String id) =>
      _run(() => repo.getReportById(id));
  @override
  Future<bool> deleteReport(String id) => _run(() => repo.deleteReport(id));
  @override
  Future<bool> updateReport(String id, ReportContent content) =>
      _run(() => repo.updateReport(id, content));
}

void main() {
  late Directory dir;
  late AppDatabase db;
  late _Account auth;
  late ReportLocalDataSource local;
  late ReportRepository repo;
  late _WidgetRepository ui;
  late ReportFormService form;
  final timestamp = DateTime.utc(2026, 11, 24, 12, 34);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('aspal-history-');
    db = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      filePath: path.join(dir.path, 'aspal.db'),
    );
    auth = _Account();
    local = ReportLocalDataSource(db);
    repo = ReportRepositoryImpl(local, auth);
    ui = _WidgetRepository(repo, Zone.current);
    form = ReportFormService(repo);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> seed(
    String id,
    String owner,
    SyncStatus status,
    DateTime time, {
    String? error,
  }) => local.insert(
    Report(
      reportId: id,
      userId: owner,
      syncStatus: status,
      createdAt: time,
      updatedAt: time,
      content: ReportContent(
        category: id,
        description: 'Jalan $id',
        severity: 'Sedang',
        latitude: -6.1,
        longitude: 106.8,
        gpsAccuracy: 4,
        gpsSource: 'camera',
      ),
      lastErrorMessage: error,
    ),
  );

  Future<void> settle(WidgetTester t) async {
    // A committed edit pops two routes and starts a second SQLite read.
    // Advance route animations and drain newly scheduled native reads together.
    for (var frame = 0; frame < 80; frame++) {
      final pending = ui.pending;
      await t.runAsync(() async {
        await pending;
      });
      await t.pump(const Duration(milliseconds: 100));
      if (!t.binding.hasScheduledFrame && identical(pending, ui.pending)) {
        return;
      }
    }
    fail('Animasi atau pembacaan SQLite belum selesai.');
  }

  void largeView(WidgetTester t) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1100, 1800);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Widget history({bool active = true}) => MaterialApp(
    home: Scaffold(
      body: MyReportHistory(repository: ui, active: active),
    ),
  );
  Future<void> tap(WidgetTester t, String label) async {
    final target = find.text(label);
    await t.ensureVisible(target);
    await t.tap(target);
    await settle(t);
  }

  testWidgets(
    'SQLite mengurutkan per akun sampai mikrodetik dan memfilter kelima status',
    (t) async {
      largeView(t);
      await t.runAsync(() async {
        for (final status in SyncStatus.values) {
          await seed(
            'A${status.index}',
            'A',
            status,
            timestamp.add(Duration(microseconds: status.index)),
          );
          await seed('B${status.index}', 'B', status, timestamp);
        }
      });
      await t.pumpWidget(history());
      await settle(t);
      List<String?> titles() => t
          .widgetList<ListTile>(find.byType(ListTile))
          .map((w) => (w.title as Text).data)
          .toList();
      expect(titles(), ['A4', 'A3', 'A2', 'A1', 'A0']);
      for (final status in SyncStatus.values) {
        await t.tap(find.widgetWithText(ChoiceChip, status.label));
        await settle(t);
        expect(titles(), ['A${status.index}']);
        expect(
          find.widgetWithText(ReportStatusLabel, status.label),
          findsOneWidget,
        );
      }
      await tap(t, 'Semua');
      expect(titles(), hasLength(5));
    },
  );

  testWidgets(
    'draft Fase 2 bertahan saat reopen, edit dan hapus dari detail memperbarui filter aktif',
    (t) async {
      largeView(t);
      final original = (await t.runAsync(() async {
        await form.save(description: 'Sebelum edit');
        final r = (await repo.getReportsByUser()).single;
        await db.close();
        return r;
      }))!;
      await t.pumpWidget(history());
      await settle(t);
      await t.tap(find.widgetWithText(ChoiceChip, 'Draft'));
      await settle(t);
      await tap(t, 'Sebelum edit');
      expect(find.text('Kategori belum dipilih'), findsOneWidget);
      expect(find.text('Lokasi belum ditentukan'), findsOneWidget);
      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.text('Foto belum tersedia'), findsOneWidget);
      expect(find.text('Belum tersedia'), findsNWidgets(2));
      expect(find.text(reportTime(original.createdAt)), findsWidgets);
      await tap(t, 'Edit atau hapus laporan');
      await tap(t, 'Selanjutnya (Isi Detail Laporan)');
      await t.enterText(find.byType(TextFormField).last, 'Sesudah edit');
      await tap(t, 'Simpan perubahan');
      expect(find.text('Sesudah edit'), findsOneWidget);
      await t.pageBack();
      await settle(t);
      expect(find.text('Sesudah edit'), findsOneWidget);
      expect(
        t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Draft')).selected,
        isTrue,
      );
      final saved = (await t.runAsync(
        () => repo.getReportById(original.reportId),
      ))!;
      expect(saved.createdAt, original.createdAt);
      expect(saved.updatedAt.isAfter(original.updatedAt), isTrue);
      await tap(t, 'Sesudah edit');
      await tap(t, 'Edit atau hapus laporan');
      await tap(t, 'Hapus laporan');
      await tap(t, 'Hapus');
      expect(
        find.text('Tidak ada laporan dengan status Draft.'),
        findsOneWidget,
      );
      await tap(t, 'Semua');
      expect(find.text('Belum ada laporan.'), findsOneWidget);
    },
  );

  testWidgets(
    'tab aktif membaca perubahan dari Lapor dan gateway tetap terisolasi',
    (t) async {
      largeView(t);
      await t.pumpWidget(history());
      await settle(t);
      expect(find.text('Belum ada laporan.'), findsOneWidget);
      await t.pumpWidget(history(active: false));
      await t.runAsync(() async {
        await form.save(description: 'Draf baru');
        await seed('B1', 'B', SyncStatus.draft, timestamp);
      });
      await t.pumpWidget(history());
      await settle(t);
      await t.tap(find.widgetWithText(ChoiceChip, 'Draft'));
      await settle(t);
      expect(find.text('Draf baru'), findsOneWidget);
      await t.pumpWidget(history(active: false));
      await t.runAsync(() async {
        final r = (await repo.getReportsByUser()).single;
        final file = await File(path.join(dir.path, 'camera.png')).writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
          ),
        );
        await form.save(
          editing: r,
          existingPath: file.path,
          category: 'Retak',
          latitude: '0',
          longitude: '0',
          source: 'manual',
          send: true,
        );
        final gateway = ReportLocalDataGateway(local);
        expect(await gateway.getUnsentItemCount('A'), 1);
        await gateway.clearUserData('B');
        expect(await gateway.getUnsentItemCount('A'), 1);
      });
      await t.pumpWidget(history());
      await settle(t);
      expect(
        find.text('Tidak ada laporan dengan status Draft.'),
        findsOneWidget,
      );
      await tap(t, 'Menunggu Sinyal');
      expect(find.text('Retak'), findsOneWidget);
    },
  );

  testWidgets(
    'detail membaca UUID milik akun, menampilkan metadata dan penyebab gagal',
    (t) async {
      largeView(t);
      await t.runAsync(() async {
        await seed(
          'Lubang',
          'A',
          SyncStatus.gagalTerkirim,
          timestamp,
          error: 'Server tidak merespons',
        );
        await seed('Rahasia', 'B', SyncStatus.draft, timestamp);
      });
      Widget detail(String id) => MaterialApp(
        home: MyReportDetail(reportId: id, repository: ui),
      );
      await t.pumpWidget(detail('Lubang'));
      await settle(t);
      // The widget test binding returns HTTP 400 for tile requests.
      expect(find.text('Peta dasar tidak tersedia.'), findsOneWidget);
      final stored = (await t.runAsync(() => repo.getReportById('Lubang')))!;
      expect(stored.syncStatus, SyncStatus.gagalTerkirim);
      expect(stored.content.latitude, -6.1);
      expect(stored.content.longitude, 106.8);
      for (final value in [
        'Lubang',
        'Sedang',
        'Jalan Lubang',
        '-6.1',
        '106.8',
        'GPS kamera',
        '4.0 m',
        'Gagal Terkirim',
        'Gagal dikirim: Server tidak merespons',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
      await t.pumpWidget(detail('Rahasia'));
      await settle(t);
      expect(
        find.text('Laporan tidak tersedia untuk akun ini.'),
        findsOneWidget,
      );
      expect(find.text('Rahasia'), findsNothing);
    },
  );

  testWidgets('marker dan pusat OSM memakai koordinat laporan SQLite', (
    t,
  ) async {
    final report = (await t.runAsync(() async {
      await seed('Peta', 'A', SyncStatus.draft, timestamp);
      return repo.getReportById('Peta');
    }))!;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportLocationMap(
            latitude: report.content.latitude,
            longitude: report.content.longitude,
            tileProvider: _MemoryTiles(),
          ),
        ),
      ),
    );
    const expected = LatLng(-6.1, 106.8);
    expect(
      t.widget<FlutterMap>(find.byType(FlutterMap)).options.initialCenter,
      expected,
    );
    expect(
      t.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point,
      expected,
    );
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    await t.pumpWidget(
      const MaterialApp(home: ReportLocationMap(latitude: 91, longitude: 0)),
    );
    expect(find.text('Lokasi belum ditentukan'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('loading dan kegagalan repository menawarkan Coba Lagi', (
    t,
  ) async {
    auth.id = null;
    await t.pumpWidget(history());
    expect(find.byType(LoadingView), findsOneWidget);
    await settle(t);
    expect(find.byType(ErrorView), findsOneWidget);
    auth.id = 'A';
    await tap(t, 'Coba Lagi');
    expect(find.text('Belum ada laporan.'), findsOneWidget);
  });

  testWidgets('foto memprioritaskan file lokal, thumbnail lalu placeholder', (
    t,
  ) async {
    const content = ReportContent(
      photoLocalPath: 'local.photo',
      thumbnailPath: 'thumb.photo',
    );
    await t.pumpWidget(const MaterialApp(home: ReportPhoto(content)));
    final image = t.widget<Image>(find.byType(Image));
    String filename(Image i) =>
        (((i.image as ResizeImage).imageProvider) as FileImage).file.path;
    expect(filename(image), 'local.photo');
    final thumb = image.errorBuilder!(
      t.element(find.byType(Image)),
      const FileSystemException(),
      null,
    ) as Image;
    expect(filename(thumb), 'thumb.photo');
    final fallback = thumb.errorBuilder!(
      t.element(find.byType(Image)),
      const FileSystemException(),
      null,
    );
    await t.pumpWidget(MaterialApp(home: fallback));
    expect(find.text('Foto belum tersedia'), findsOneWidget);
  });
}
