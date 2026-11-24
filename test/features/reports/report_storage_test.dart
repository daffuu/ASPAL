import 'dart:io';

import 'package:aspal/core/database/app_database.dart';
import 'package:aspal/features/auth/domain/repositories/token_provider.dart';
import 'package:aspal/features/reports/data/report_mapper.dart';
import 'package:aspal/features/reports/domain/models/report.dart';
import 'package:aspal/features/reports/domain/models/sync_status.dart';
import 'package:aspal/features/reports/reports_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Account extends Fake implements TokenProvider {
  String? userId = 'A';
  @override
  Future<String?> getUserId() async => userId;
}

void main() {
  late Directory directory;
  late AppDatabase store;
  late ReportsModule module;
  late _Account account;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('aspal_reports_');
    store = AppDatabase(
      factory: databaseFactoryFfi,
      filePath: path.join(directory.path, 'aspal.db'),
    );
    account = _Account();
    module = ReportsModule(store, account);
  });
  tearDown(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  test(
    'migration v1 creates both tables and the account/status indexes',
    () async {
      final db = await store.database;
      expect(await store.database, same(db));
      expect(await db.getVersion(), 1);
      final schema = await db.query('sqlite_master', columns: ['name']);
      expect(
        schema.map((row) => row['name']),
        containsAll([
          'reports',
          'sync_attempts',
          'reports_user',
          'reports_status',
          'reports_user_status',
          'reports_user_created',
          'attempts_entity',
          'reports_delete_attempts',
        ]),
      );
      final columns = await db.rawQuery('PRAGMA table_info(sync_attempts)');
      expect(
        columns.map((row) => row['name']),
        unorderedEquals([
          'attempt_id',
          'entity_type',
          'entity_id',
          'attempt_no',
          'attempted_at',
          'trigger',
          'result',
          'http_status',
          'error_code',
          'error_message',
        ]),
      );
    },
  );

  test(
    'incomplete draft, stable UUID, nullable edits and disk persistence',
    () async {
      final repo = module.repository;
      final draft = await repo.createReport();
      expect(
        draft.reportId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      final saved = (await repo.getReportById(draft.reportId))!;
      expect(saved.content.category, isNull);
      expect(saved.content.photoLocalPath, isNull);
      expect(saved.content.latitude, isNull);
      expect(saved.retryCount, 0);
      expect(saved.syncStatus, SyncStatus.draft);
      expect(saved.userId, 'A');
      expect(
        await repo.updateReport(
          draft.reportId,
          const ReportContent(description: "O'Brien"),
        ),
        isTrue,
      );
      await store.close();
      final reopened = (await repo.getReportsByUser()).single;
      expect(reopened.reportId, draft.reportId);
      expect(reopened.createdAt, draft.createdAt);
      expect(reopened.content.description, "O'Brien");
      expect(
        await repo.updateReport(draft.reportId, const ReportContent()),
        isTrue,
      );
      expect(
        (await repo.getReportById(draft.reportId))!.content.description,
        isNull,
      );
      expect(await repo.deleteReport(draft.reportId), isTrue);
      expect(await repo.getReportById(draft.reportId), isNull);
    },
  );

  test(
    'account switch isolates reads, edits, deletes and sessionless access',
    () async {
      final repo = module.repository;
      account.userId = 'B';
      final b = await repo.createReport();
      account.userId = 'A';
      final a = await repo.createReport();
      expect((await repo.getReportsByUser()).single.reportId, a.reportId);
      expect(
        (await repo.getReportsByStatus(SyncStatus.draft)).single.reportId,
        a.reportId,
      );
      expect(await repo.getReportById(b.reportId), isNull);
      expect(
        await repo.updateReport(
          b.reportId,
          const ReportContent(category: 'retak'),
        ),
        isFalse,
      );
      expect(await repo.deleteReport(b.reportId), isFalse);
      await repo.clearUserData();
      account.userId = 'B';
      expect((await repo.getReportById(b.reportId))!.content.category, isNull);
      account.userId = null;
      await expectLater(repo.createReport(), throwsStateError);
      await expectLater(repo.getReportsByUser(), throwsStateError);
    },
  );

  for (final status in SyncStatus.values) {
    test(
      '${status.databaseValue} filter, unsent count and edit/delete locks',
      () async {
        final repo = module.repository;
        final db = await store.database;
        final draft = await repo.createReport();
        await db.update(
          'reports',
          {'sync_status': status.databaseValue},
          where: 'report_id = ? AND user_id = ?',
          whereArgs: [draft.reportId, 'A'],
        );
        final filtered = await repo.getReportsByStatus(status);
        expect(filtered.single.reportId, draft.reportId);
        expect(filtered.single.syncStatus, status);
        final unsent = status == SyncStatus.terkirim ? 0 : 1;
        expect(await repo.countUnsentReports(), unsent);
        expect(await module.gateway.getUnsentItemCount('A'), unsent);
        final editable = [
          SyncStatus.draft,
          SyncStatus.gagalTerkirim,
        ].contains(status);
        expect(
          await repo.updateReport(draft.reportId, const ReportContent()),
          editable,
        );
        expect(await repo.deleteReport(draft.reportId), editable);
        expect(await repo.getReportsByUser(), hasLength(editable ? 0 : 1));
      },
    );
  }

  test('logout clears only report rows and attempts belonging to the requested account', () async {
    final a = await module.repository.createReport();
    account.userId = 'B';
    final b = await module.repository.createReport();
    final db = await store.database;
    for (final (type, id) in [
      ('report', a.reportId),
      ('followup', a.reportId),
      ('report', b.reportId),
    ]) {
      await db.insert('sync_attempts', {
        'entity_type': type,
        'entity_id': id,
        'attempt_no': 1,
        'attempted_at': '2026-01-01T00:00:00.000Z',
        'trigger': 'manual',
        'result': 'failed',
      });
    }
    await module.gateway.clearUserData('A');
    await module.gateway.clearUserData('A');
    expect(await module.gateway.getUnsentItemCount('A'), 0);
    expect(await module.gateway.getUnsentItemCount('B'), 1);
    expect(
      (await module.repository.getReportsByUser()).single.reportId,
      b.reportId,
    );
    final attempts = await db.query('sync_attempts');
    expect(
      attempts.map((row) => (row['entity_type'], row['entity_id'])),
      unorderedEquals([('followup', a.reportId), ('report', b.reportId)]),
    );
  });

  test('mapper round-trips all columns through SQLite and encodes timestamps in UTC', () async {
    final db = await store.database;
    final time = DateTime.parse('2026-01-02T09:00:00.123456+07:00').toLocal();
    final report = Report(
      reportId: 'fixture',
      userId: 'A',
      createdAt: time,
      updatedAt: time,
      syncedAt: time,
      lastAttemptAt: time,
      nextRetryAt: time,
      retryCount: 2,
      syncStatus: SyncStatus.terkirim,
      serverReportId: 'server',
      roadCondition: 'MASIH_RUSAK',
      photoRemoteUrl: 'remote',
      lastErrorMessage: 'offline',
      content: const ReportContent(
        category: 'retak',
        severity: 'berat',
        description: 'jalan',
        latitude: -6,
        longitude: 107,
        gpsAccuracy: 3.5,
        gpsSource: 'manual',
        photoLocalPath: 'photo',
        thumbnailPath: 'thumb',
        photoSizeBytes: 42,
      ),
    );
    final row = reportToRow(report);
    await db.insert('reports', row);
    final restored = (await module.repository.getReportById(report.reportId))!;
    expect(reportToRow(restored), row);
    expect(row.length, 23);
    for (final key in [
      'created_at',
      'updated_at',
      'synced_at',
      'last_attempt_at',
      'next_retry_at',
    ]) {
      expect(row[key], '2026-01-02T02:00:00.123456Z');
    }
    expect(restored.syncedAt!.isUtc, isTrue);
    expect(restored.syncedAt!.isAtSameMomentAs(time), isTrue);
    expect(SyncStatus.values.map((s) => s.databaseValue), [
      'DRAFT',
      'MENUNGGU_SINYAL',
      'MENGIRIM',
      'GAGAL_TERKIRIM',
      'TERKIRIM',
    ]);
  });
}
