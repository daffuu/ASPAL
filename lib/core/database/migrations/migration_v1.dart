import 'package:sqflite/sqflite.dart';

Future<void> migrateV1(Database db) async {
  await db.execute('''
    CREATE TABLE reports (
      report_id TEXT NOT NULL PRIMARY KEY,
      user_id TEXT NOT NULL,
      category TEXT, severity TEXT, description TEXT,
      latitude REAL, longitude REAL, gps_accuracy REAL, gps_source TEXT,
      photo_local_path TEXT, photo_remote_url TEXT, thumbnail_path TEXT,
      photo_size_bytes INTEGER,
      sync_status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (
        sync_status IN ('DRAFT','MENUNGGU_SINYAL','MENGIRIM','GAGAL_TERKIRIM','TERKIRIM')
      ),
      road_condition TEXT, server_report_id TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL, synced_at TEXT,
      retry_count INTEGER NOT NULL DEFAULT 0, last_attempt_at TEXT,
      next_retry_at TEXT, last_error_message TEXT
    )
  ''');
  await db.execute('CREATE INDEX reports_user ON reports(user_id)');
  await db.execute('CREATE INDEX reports_status ON reports(sync_status)');
  await db.execute(
    'CREATE INDEX reports_user_status ON reports(user_id, sync_status)',
  );
  await db.execute(
    'CREATE INDEX reports_user_created ON reports(user_id, created_at)',
  );
  await db.execute('''
    CREATE TABLE sync_attempts (
      attempt_id INTEGER PRIMARY KEY, entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL, attempt_no INTEGER NOT NULL, attempted_at TEXT NOT NULL,
      trigger TEXT NOT NULL, result TEXT NOT NULL, http_status INTEGER,
      error_code TEXT, error_message TEXT
    )
  ''');
  await db.execute(
    'CREATE INDEX attempts_entity ON sync_attempts(entity_type, entity_id)',
  );
  await db.execute('''
    CREATE TRIGGER reports_delete_attempts AFTER DELETE ON reports BEGIN
      DELETE FROM sync_attempts WHERE entity_type = 'report' AND entity_id = OLD.report_id;
    END
  ''');
}
