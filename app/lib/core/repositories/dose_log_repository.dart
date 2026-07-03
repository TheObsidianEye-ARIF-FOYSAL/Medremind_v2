import 'dart:async';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/dose_log.dart';

class DoseLogRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _controller = StreamController<List<DoseLog>>.broadcast();

  Stream<List<DoseLog>> get watchAll => _controller.stream;

  DoseLogRepository(this._db);

  Future<List<DoseLog>> getForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .millisecondsSinceEpoch;
    final db = await _db.database;
    final rows = await db.query(
      'dose_logs',
      where: 'scheduled_for BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'scheduled_for ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<DoseLog>> getRange(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      'dose_logs',
      where: 'scheduled_for BETWEEN ? AND ?',
      whereArgs: [
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_for ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<DoseLog> createPending({
    required String doseGroupId,
    required DateTime scheduledFor,
  }) async {
    final log = DoseLog(
      id: _uuid.v4(),
      doseGroupId: doseGroupId,
      scheduledFor: scheduledFor,
      status: DoseStatus.pending,
    );
    final db = await _db.database;
    await db.insert('dose_logs', _toRow(log));
    _notify();
    return log;
  }

  Future<void> updateStatus(
    String id,
    DoseStatus status, {
    DateTime? actedAt,
  }) async {
    final db = await _db.database;
    await db.update(
      'dose_logs',
      {
        'status': status.name,
        'acted_at': (actedAt ?? DateTime.now()).millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notify();
  }

  Future<void> _notify() async {
    final today = await getForDate(DateTime.now());
    _controller.add(today);
  }

  static DoseLog _fromRow(Map<String, dynamic> r) => DoseLog(
        id: r['id'] as String,
        doseGroupId: r['dose_group_id'] as String,
        scheduledFor: DateTime.fromMillisecondsSinceEpoch(
            r['scheduled_for'] as int),
        status: DoseStatus.values.firstWhere(
          (s) => s.name == (r['status'] as String),
          orElse: () => DoseStatus.pending,
        ),
        actedAt: r['acted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['acted_at'] as int)
            : null,
      );

  static Map<String, dynamic> _toRow(DoseLog l) => {
        'id': l.id,
        'dose_group_id': l.doseGroupId,
        'scheduled_for': l.scheduledFor.millisecondsSinceEpoch,
        'status': l.status.name,
        'acted_at': l.actedAt?.millisecondsSinceEpoch,
      };

  void dispose() => _controller.close();
}
