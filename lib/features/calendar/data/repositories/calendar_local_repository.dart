import 'package:jg_business/features/calendar/data/models/calendar_event_entity.dart';
import 'package:jg_business/shared/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class CalendarLocalRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> upsertEvent(CalendarEventEntity event) async {
    final db = await _db;
    await db.insert(
      'calendar_events',
      event.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEvent(String id) async {
    final db = await _db;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CalendarEventEntity>> getAllEvents() async {
    final db = await _db;
    final rows = await db.query(
      'calendar_events',
      orderBy: 'COALESCE(start_date_time, start_date) ASC',
    );

    return rows.map(CalendarEventEntity.fromDb).toList();
  }

  Future<void> saveSyncToken(String token) async {
    final db = await _db;
    await db.insert('app_kv', {
      'key': 'calendar_sync_token',
      'value': token,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSyncToken() async {
    final db = await _db;
    final rows = await db.query(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['calendar_sync_token'],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> clearSyncToken() async {
    final db = await _db;
    await db.delete(
      'app_kv',
      where: 'key = ?',
      whereArgs: ['calendar_sync_token'],
    );
  }

  Future<void> clearEvents() async {
    final db = await _db;
    await db.delete('calendar_events');
  }
}
