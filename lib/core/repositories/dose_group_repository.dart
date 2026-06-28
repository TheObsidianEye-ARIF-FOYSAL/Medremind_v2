import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/dose_group.dart';
import '../models/dose_item.dart';

class DoseGroupRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _controller = StreamController<List<DoseGroup>>.broadcast();

  Stream<List<DoseGroup>> get watchAll => _controller.stream;

  DoseGroupRepository(this._db);

  Future<List<DoseGroup>> getAll({bool activeOnly = false}) async {
    final db = await _db.database;
    final where = activeOnly ? 'is_active = 1' : null;
    final rows = await db.query('dose_groups', where: where,
        orderBy: 'time_of_day ASC');
    final groups = <DoseGroup>[];
    for (final row in rows) {
      final items = await _itemsForGroup(row['id'] as String);
      groups.add(_fromRow(row, items));
    }
    return groups;
  }

  Future<DoseGroup?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('dose_groups', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final items = await _itemsForGroup(id);
    return _fromRow(rows.first, items);
  }

  /// Insert a DoseGroup and its items in a transaction.
  Future<DoseGroup> insert({
    required String label,
    required String timeOfDay,
    MealRelation mealRelation = MealRelation.none,
    List<int> daysOfWeek = const [],
    required DateTime startDate,
    DateTime? endDate,
    bool isActive = true,
    required List<({String medicineId, double quantity})> items,
  }) async {
    final groupId = _uuid.v4();
    final group = DoseGroup(
      id: groupId,
      label: label,
      timeOfDay: timeOfDay,
      mealRelation: mealRelation,
      daysOfWeek: daysOfWeek,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      items: items
          .map((e) => DoseItem(
                id: _uuid.v4(),
                doseGroupId: groupId,
                medicineId: e.medicineId,
                quantity: e.quantity,
              ))
          .toList(),
    );

    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('dose_groups', _groupToRow(group));
      for (final item in group.items) {
        await txn.insert('dose_items', _itemToRow(item));
      }
    });
    _notify();
    return group;
  }

  Future<void> setActive(String id, {required bool active}) async {
    final db = await _db.database;
    await db.update('dose_groups', {'is_active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('dose_groups', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<List<DoseItem>> _itemsForGroup(String groupId) async {
    final db = await _db.database;
    final rows = await db.query('dose_items',
        where: 'dose_group_id = ?', whereArgs: [groupId]);
    return rows.map(_itemFromRow).toList();
  }

  Future<void> _notify() async {
    final all = await getAll();
    _controller.add(all);
  }

  static DoseGroup _fromRow(Map<String, dynamic> r, List<DoseItem> items) =>
      DoseGroup(
        id: r['id'] as String,
        label: r['label'] as String,
        timeOfDay: r['time_of_day'] as String,
        mealRelation: MealRelation.values.firstWhere(
          (m) => m.name == (r['meal_relation'] as String),
          orElse: () => MealRelation.none,
        ),
        daysOfWeek: (jsonDecode(r['days_of_week'] as String) as List)
            .map((e) => e as int)
            .toList(),
        startDate: DateTime.fromMillisecondsSinceEpoch(r['start_date'] as int),
        endDate: r['end_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(r['end_date'] as int)
            : null,
        isActive: (r['is_active'] as int) == 1,
        items: items,
      );

  static Map<String, dynamic> _groupToRow(DoseGroup g) => {
        'id': g.id,
        'label': g.label,
        'time_of_day': g.timeOfDay,
        'meal_relation': g.mealRelation.name,
        'days_of_week': jsonEncode(g.daysOfWeek),
        'start_date': g.startDate.millisecondsSinceEpoch,
        'end_date': g.endDate?.millisecondsSinceEpoch,
        'is_active': g.isActive ? 1 : 0,
      };

  static DoseItem _itemFromRow(Map<String, dynamic> r) => DoseItem(
        id: r['id'] as String,
        doseGroupId: r['dose_group_id'] as String,
        medicineId: r['medicine_id'] as String,
        quantity: (r['quantity'] as num).toDouble(),
      );

  static Map<String, dynamic> _itemToRow(DoseItem i) => {
        'id': i.id,
        'dose_group_id': i.doseGroupId,
        'medicine_id': i.medicineId,
        'quantity': i.quantity,
      };

  void dispose() => _controller.close();
}
