import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_v1.dart';

class AppDatabase {
  AppDatabase({this.factory, this.filePath});

  static final instance = AppDatabase();
  final DatabaseFactory? factory;
  final String? filePath;
  Future<Database>? _connection;

  // Append migrations in version order. sqflite wraps create/upgrade in a transaction.
  static const _migrations = [migrateV1];

  Future<Database> get database => _connection ??= _open();

  Future<Database> _open() async {
    try {
      final driver = factory ?? databaseFactory;
      final location =
          filePath ?? path.join(await driver.getDatabasesPath(), 'aspal.db');
      return await driver.openDatabase(
        location,
        options: OpenDatabaseOptions(
          version: _migrations.length,
          onCreate: (db, version) => _migrate(db, 0, version),
          onUpgrade: _migrate,
        ),
      );
    } catch (_) {
      _connection = null;
      rethrow;
    }
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var index = from; index < to; index++) {
      await _migrations[index](db);
    }
  }

  Future<void> close() async {
    final connection = await _connection;
    await connection?.close();
    _connection = null;
  }
}
