import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jg_business.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE calendar_events (
            id TEXT PRIMARY KEY,
            summary TEXT,
            description TEXT,
            location TEXT,
            status TEXT,
            start_date_time TEXT,
            start_date TEXT,
            end_date_time TEXT,
            end_date TEXT,
            updated TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE app_kv (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }
}
