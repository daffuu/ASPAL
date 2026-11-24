import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aspal/core/database/app_database.dart';
import 'package:aspal/features/auth/domain/repositories/token_provider.dart';
import 'package:aspal/features/reports/data/report_capture.dart';
import 'package:aspal/features/reports/data/report_local_data_source.dart';
import 'package:aspal/features/reports/data/report_photos.dart';
import 'package:aspal/features/reports/data/report_repository_impl.dart';
import 'package:aspal/features/reports/domain/models/report_validation.dart';
import 'package:aspal/features/reports/domain/models/report.dart';
import 'package:aspal/features/reports/domain/models/sync_status.dart';
import 'package:aspal/features/reports/domain/repositories/report_repository.dart';
import 'package:aspal/features/reports/report_form_service.dart';
import 'package:aspal/screens/offline_geotagging_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Account extends Fake implements TokenProvider {
  String? id = 'alice';
  @override
  Future<String?> getUserId() async => id;
}

class _DialogRepository extends Fake implements ReportRepository {
  _DialogRepository(this.editable);
  final Report editable;
  final deleted = <String>[];
  @override
  Future<List<Report>> getReportsByUser() async => [editable];
  @override
  Future<bool> deleteReport(String id) async {
    deleted.add(id);
    return true;
  }
}

class _ObservedRepository extends ReportRepositoryImpl {
  _ObservedRepository(super.local, super.auth);
  late final Completer<Report> inserted;
  @override
  Future<Report> createReport([
    ReportContent content = const ReportContent(),
  ]) async {
    final report = await super.createReport(content);
    inserted.complete(report);
    return report;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
  );
  late Directory dir;
  late AppDatabase db;
  late ReportPhotos photos;
  late ReportFormService form;
  late _Account account;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('aspal_form_');
    db = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      filePath: path.join(dir.path, 'aspal.db'),
    );
    photos = ReportPhotos(supportDirectory: () async => dir);
    account = _Account();
    form = ReportFormService(
      ReportRepositoryImpl(ReportLocalDataSource(db, photos: photos), account),
      photos: photos,
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'draft kosong, edit stabil, Kirim atomik, persisten setelah restart',
    () async {
      await form.save();
      final repo = form.repository;
      final first = (await repo.getReportsByUser()).single;
      expect(first.userId, 'alice');
      expect(first.reportId, matches(RegExp(r'^[0-9a-f-]{14}4[0-9a-f-]{21}$')));
      expect(first.syncStatus, SyncStatus.draft);
      expect(first.content.category, isNull);
      await expectLater(
        form.save(editing: first, send: true),
        throwsFormatException,
      );
      expect(
        (await repo.getReportById(first.reportId))!.syncStatus,
        SyncStatus.draft,
      );
      await form.save(editing: first, category: 'Retak', latitude: '-6');
      final edited = (await repo.getReportsByUser()).single;
      expect(edited.reportId, first.reportId);
      expect(edited.createdAt, first.createdAt);
      expect(edited.updatedAt.isAfter(first.updatedAt), isTrue);
      await form.save(
        editing: edited,
        send: true,
        category: 'Retak',
        newPhoto: png,
        source: 'manual',
        latitude: '-6.1',
        longitude: '107',
      );
      await db.close();
      final queued = (await repo.getReportsByUser()).single;
      expect(queued.reportId, first.reportId);
      expect(queued.syncStatus, SyncStatus.menungguSinyal);
      expect(
        queued.content.photoSizeBytes,
        await File(queued.content.photoLocalPath!).length(),
      );
      expect(queued.content.latitude, -6.1);
      expect(queued.content.longitude, 107);
      expect(queued.content.gpsSource, 'manual');
      expect(await repo.countUnsentReports(), 1);
      await expectLater(form.save(editing: queued), throwsStateError);
      expect(await repo.deleteReport(queued.reportId), isFalse);
    },
  );

  test('Kirim baru memerlukan foto, kategori, dan kedua koordinat', () async {
    for (final (category, lat, lon) in [
      (null, '0', '0'),
      ('Retak', '', '0'),
      ('Retak', '0', ''),
    ]) {
      await expectLater(
        form.save(
          send: true,
          newPhoto: png,
          category: category,
          latitude: lat,
          longitude: lon,
        ),
        throwsFormatException,
      );
    }
    expect(await form.repository.getReportsByUser(), isEmpty);
    expect(
      await Directory(path.join(dir.path, 'report_photos')).list().isEmpty,
      isTrue,
    );
    await form.save(
      send: true,
      category: 'Amblas',
      source: 'camera',
      accuracy: 3,
      latitude: '90',
      longitude: '-180',
      newPhoto: png,
    );
    final report = (await form.repository.getReportsByUser()).single;
    expect(report.syncStatus, SyncStatus.menungguSinyal);
    expect(report.content.gpsAccuracy, 3);
  });

  test(
    'koordinat kosong dan batas inklusif, menolak non-numeric dan non-finite',
    () {
      for (final bound in [90, 180]) {
        expect(parseCoordinate('', bound, 'GPS'), isNull);
        for (final n in [-bound, bound]) {
          expect(parseCoordinate(n.toString(), bound, 'GPS'), n);
        }
        for (final text in [
          'abc',
          'NaN',
          'Infinity',
          '-${bound + 1}',
          '${bound + 1}',
        ]) {
          expect(
            () => parseCoordinate(text, bound, 'GPS'),
            throwsFormatException,
          );
        }
      }
    },
  );

  test('edit gagal terkirim, isolasi akun, ganti foto, hapus salinan milik aplikasi', () async {
    final original = await File(path.join(dir.path, 'gallery.png'))
        .writeAsBytes(png);
    await form.save(newPhoto: await original.readAsBytes());
    final r = (await form.repository.getReportsByUser()).single;
    final old = File(r.content.photoLocalPath!);
    final sql = await db.database;
    await sql.update(
      'reports',
      {'sync_status': 'GAGAL_TERKIRIM'},
      where: 'report_id = ? AND user_id = ?',
      whereArgs: [r.reportId, 'alice'],
    );
    account.id = 'bob';
    await expectLater(form.save(editing: r, newPhoto: png), throwsStateError);
    expect(await form.repository.deleteReport(r.reportId), isFalse);
    expect(await old.exists(), isTrue);
    account.id = 'alice';
    await form.save(
      editing: r,
      newPhoto: png,
      category: 'Retak',
      description: 'Baru',
    );
    final changed = (await form.repository.getReportsByUser()).single;
    expect(changed.syncStatus, SyncStatus.gagalTerkirim);
    expect(changed.reportId, r.reportId);
    expect(await old.exists(), isFalse);
    await expectLater(
      form.save(
        editing: changed,
        existingPath: changed.content.photoLocalPath,
        source: 'manual',
        latitude: '1',
        longitude: '2',
        category: 'Retak',
        send: true,
      ),
      throwsStateError,
    );
    expect(await form.repository.deleteReport(r.reportId), isTrue);
    expect(await File(changed.content.photoLocalPath!).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

  test('media besar diperkecil dan jumlah byte file akhir diverifikasi', () async {
    // Uncompressed 1024 × 1024, 24-bit BMP, with a deterministic noise pattern.
    const side = 1024;
    final input = Uint8List(54 + side * side * 3);
    final header = ByteData.sublistView(input);
    input.setAll(0, [0x42, 0x4d]);
    for (final (offset, value) in [
      (2, input.length),
      (10, 54),
      (14, 40),
      (18, side),
      (22, side),
    ]) {
      header.setUint32(offset, value, Endian.little);
    }
    header.setUint16(26, 1, Endian.little);
    header.setUint16(28, 24, Endian.little);
    final random = Random(42);
    for (var i = 54; i < input.length; i++) {
      input[i] = random.nextInt(256);
    }
    final result = await photos.prepare(input);
    final file = await photos.persist(result);
    expect(await file.length(), inInclusiveRange(1, ReportPhotos.limit));
    expect(await file.length(), result.length);
    await expectLater(photos.persist(input), throwsFormatException);
    await expectLater(photos.prepare(Uint8List(5)), throwsA(anything));
    final outside = await File(path.join(dir.path, 'outside.photo'))
        .writeAsBytes(png);
    await photos.discard(outside.path);
    expect(await outside.exists(), isTrue);
  });

  test('picker dibatalkan dan galeri tidak mengakses GPS', () async {
    var locations = 0;
    final gallery = ReportCapture(
      pick: (_) async => XFile.fromData(png),
      locate: () async {
        locations++;
        throw StateError('unexpected');
      },
    );
    expect(
      await ReportCapture(
        pick: (_) async => null,
        locate: gallery.locate,
      ).capture(ImageSource.camera),
      isNull,
    );
    final result = await gallery.capture(ImageSource.gallery);
    expect(result!.source, 'manual');
    expect(result.location, isNull);
    expect(locations, 0);
  });

  test('GPS gagal tetap menyimpan foto draft kamera', () async {
    final capture = ReportCapture(
      pick: (_) async => XFile.fromData(png),
      locate: () async => throw const FormatException('Izin lokasi ditolak.'),
    );
    final photo = (await capture.capture(ImageSource.camera))!;
    expect(photo.warning, contains('ditolak'));
    await form.save(newPhoto: photo.bytes, source: photo.source);
    final saved = (await form.repository.getReportsByUser()).single;
    expect(saved.content.gpsSource, 'camera');
    expect(saved.content.latitude, isNull);
    expect(saved.syncStatus, SyncStatus.draft);
    expect(await File(saved.content.photoLocalPath!).exists(), isTrue);
  });

  test('file hilang dan sesi kosong tidak menambahkan laporan', () async {
    await expectLater(
      form.save(existingPath: path.join(dir.path, 'missing')),
      throwsA(isA<FileSystemException>()),
    );
    account.id = null;
    await expectLater(form.save(newPhoto: png), throwsStateError);
    account.id = 'alice';
    expect(await form.repository.getReportsByUser(), isEmpty);
  });
  testWidgets('tombol Simpan Draft menulis baris SQLite dari tab Lapor', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await db.database;
    });
    final observed = _ObservedRepository(
      ReportLocalDataSource(db, photos: photos),
      account,
    );
    final screenService = ReportFormService(observed, photos: photos);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineGeotaggingCamera(service: screenService)),
      ),
    );
    Future<void> tapLabel(String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tapLabel('Selanjutnya (Isi Detail Laporan)');
    final save = find.widgetWithText(OutlinedButton, 'Simpan Draft');
    await tester.ensureVisible(save);
    // Run the actual button callback with the real event loop for native SQLite.
    await tester.runAsync(() async {
      observed.inserted = Completer<Report>();
      tester.widget<OutlinedButton>(save).onPressed!();
      await observed.inserted.future.timeout(const Duration(seconds: 5));
    });
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(form.repository.getReportsByUser);
    expect(rows!.single.userId, 'alice');
    expect(rows.single.syncStatus, SyncStatus.draft);
  });
  test(
    'kamera menyimpan lokasi otomatis, akurasi dan ukuran foto terpilih',
    () async {
      final capture = ReportCapture(
        pick: (_) async => XFile.fromData(png),
        locate: () async => (latitude: -6.23, longitude: 107.42, accuracy: 4.5),
      );
      final photo = (await capture.capture(ImageSource.camera))!;
      final location = photo.location!;
      await form.save(
        source: photo.source,
        newPhoto: photo.bytes,
        category: 'Lubang',
        latitude: location.latitude.toString(),
        longitude: location.longitude.toString(),
        accuracy: location.accuracy,
        send: true,
      );
      final report = (await form.repository.getReportsByUser()).single;
      expect(report.content.gpsSource, 'camera');
      expect(report.content.latitude, -6.23);
      expect(report.content.longitude, 107.42);
      expect(report.content.gpsAccuracy, 4.5);
      expect(report.content.photoSizeBytes, png.length);
    },
  );

  testWidgets(
    'aksi hapus meminta konfirmasi dan Batal mempertahankan laporan',
    (tester) async {
      final repo = _DialogRepository(
        Report(
          reportId: 'fixture',
          userId: 'alice',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineGeotaggingCamera(service: ReportFormService(repo)),
          ),
        ),
      );
      Future<void> tap(String label) async {
        final target = find.text(label);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('Buka laporan untuk diedit');
      await tap('Draft tanpa judul');
      await tap('Hapus laporan');
      await tap('Batal');
      expect(repo.deleted, isEmpty);
      await tap('Hapus laporan');
      await tap('Hapus');
      expect(repo.deleted, ['fixture']);
    },
  );
}
