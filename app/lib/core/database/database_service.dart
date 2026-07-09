import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // path_provider has no web implementation (no filesystem) — on web,
    // sqflite is backed by IndexedDB via sqflite_common_ffi_web instead, and
    // just needs a plain db name rather than a directory-qualified path.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        'med_remind_v2.db',
        version: 1,
        onCreate: _onCreate,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'med_remind_v2.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        brand_name TEXT NOT NULL,
        generic_group_id TEXT,
        form TEXT NOT NULL DEFAULT 'tablet',
        strength TEXT NOT NULL DEFAULT '',
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_groups (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        meal_relation TEXT NOT NULL DEFAULT 'none',
        days_of_week TEXT NOT NULL DEFAULT '[]',
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_items (
        id TEXT PRIMARY KEY,
        dose_group_id TEXT NOT NULL,
        medicine_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        FOREIGN KEY (dose_group_id) REFERENCES dose_groups(id) ON DELETE CASCADE,
        FOREIGN KEY (medicine_id) REFERENCES medicines(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_logs (
        id TEXT PRIMARY KEY,
        dose_group_id TEXT NOT NULL,
        scheduled_for INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        acted_at INTEGER
      )
    ''');

    // Index for common queries
    await db.execute(
        'CREATE INDEX idx_dose_logs_scheduled ON dose_logs(scheduled_for)');
    await db.execute(
        'CREATE INDEX idx_dose_logs_group ON dose_logs(dose_group_id)');
    await db.execute(
        'CREATE INDEX idx_dose_items_group ON dose_items(dose_group_id)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
