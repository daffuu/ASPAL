import 'package:flutter/foundation.dart';

import 'report_photos.dart';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/models/report.dart';
import '../domain/models/sync_status.dart';
import 'report_mapper.dart';

class ReportLocalDataSource {
  const ReportLocalDataSource(
    this._database, {
    this.photos = const ReportPhotos(),
  });
  final ReportPhotos photos;
  final AppDatabase _database;
  static const _owned = 'report_id = ? AND user_id = ?';
  static const _editable =
      "$_owned AND sync_status IN ('DRAFT', 'GAGAL_TERKIRIM')";

  Future<void> insert(Report report) async {
    await (await _database.database).insert('reports', reportToRow(report));
  }

  Future<Report?> getById(String userId, String reportId) async {
    final rows = await (await _database.database).query(
      'reports',
      where: _owned,
      whereArgs: [reportId, userId],
    );
    return rows.isEmpty ? null : reportFromRow(rows.single);
  }

  Future<List<Report>> list(String userId, {SyncStatus? status}) async {
    final rows = await (await _database.database).query(
      'reports',
      where: status == null ? 'user_id = ?' : 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, if (status != null) status.databaseValue],
      // ISO UTC uses 3 or 6 fractional digits. Ignore Z so an exact
      // millisecond sorts before later microseconds in that millisecond.
      orderBy: "rtrim(created_at, 'Z') DESC, report_id ASC",
    );
    return rows.map(reportFromRow).toList();
  }

  Future<bool> update(
    String userId,
    String reportId,
    ReportContent content, {
    bool queue = false,
  }) async {
    final where = queue ? "$_owned AND sync_status = 'DRAFT'" : _editable;
    final args = [reportId, userId];
    final result = await (await _database.database).transaction((tx) async {
      final rows = await tx.query(
        'reports',
        columns: ['photo_local_path'],
        where: where,
        whereArgs: args,
      );
      if (rows.isEmpty) return (false, null);
      await tx.update(
        'reports',
        {
          ...contentToRow(content),
          if (queue) 'sync_status': SyncStatus.menungguSinyal.databaseValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: where,
        whereArgs: args,
      );
      return (true, rows.single['photo_local_path'] as String?);
    });
    if (result.$2 != content.photoLocalPath) await _discard(result.$2);
    return result.$1;
  }

  Future<void> _discard(String? name) async {
    try {
      await photos.discard(name);
    } catch (error) {
      // The row has committed. Never retry the write or remove its new photo.
      debugPrint('Pembersihan foto laporan tertunda: $error');
    }
  }

  Future<bool> delete(String userId, String reportId) =>
      _deleteWhere(_editable, [reportId, userId]);

  Future<bool> _deleteWhere(String where, List<String> args) async {
    final rows = await (await _database.database).transaction((tx) async {
      final rows = await tx.query(
        'reports',
        columns: ['photo_local_path'],
        where: where,
        whereArgs: args,
      );
      await tx.delete('reports', where: where, whereArgs: args);
      return rows;
    });
    for (final row in rows) {
      await _discard(row['photo_local_path'] as String?);
    }
    return rows.isNotEmpty;
  }

  Future<int> countUnsent(String userId) async {
    final rows = await (await _database.database).rawQuery(
      'SELECT COUNT(*) FROM reports WHERE user_id = ? AND sync_status <> ?',
      [userId, SyncStatus.terkirim.databaseValue],
    );
    return Sqflite.firstIntValue(rows)!;
  }

  Future<void> clearUserData(String userId) async {
    await _deleteWhere('user_id = ?', [userId]);
  }
}
