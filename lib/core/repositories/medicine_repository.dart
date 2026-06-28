import 'dart:async';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/medicine.dart';

class MedicineRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  // Stream controller so UI can reactively rebuild.
  final _controller = StreamController<List<Medicine>>.broadcast();
  Stream<List<Medicine>> get watchAll => _controller.stream;

  MedicineRepository(this._db);

  Future<List<Medicine>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('medicines', orderBy: 'brand_name ASC');
    return rows.map(_fromRow).toList();
  }

  Future<Medicine?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<Medicine> insert({
    required String brandName,
    String? genericGroupId,
    MedicineForm form = MedicineForm.tablet,
    String strength = '',
    String? notes,
  }) async {
    final medicine = Medicine(
      id: _uuid.v4(),
      brandName: brandName,
      genericGroupId: genericGroupId,
      form: form,
      strength: strength,
      notes: notes,
    );
    final db = await _db.database;
    await db.insert('medicines', _toRow(medicine));
    _notify();
    return medicine;
  }

  Future<void> update(Medicine medicine) async {
    final db = await _db.database;
    await db.update('medicines', _toRow(medicine),
        where: 'id = ?', whereArgs: [medicine.id]);
    _notify();
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> _notify() async {
    final all = await getAll();
    _controller.add(all);
  }

  static Medicine _fromRow(Map<String, dynamic> r) => Medicine(
        id: r['id'] as String,
        brandName: r['brand_name'] as String,
        genericGroupId: r['generic_group_id'] as String?,
        form: MedicineForm.values.firstWhere(
          (f) => f.name == (r['form'] as String),
          orElse: () => MedicineForm.tablet,
        ),
        strength: r['strength'] as String? ?? '',
        notes: r['notes'] as String?,
      );

  static Map<String, dynamic> _toRow(Medicine m) => {
        'id': m.id,
        'brand_name': m.brandName,
        'generic_group_id': m.genericGroupId,
        'form': m.form.name,
        'strength': m.strength,
        'notes': m.notes,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

  void dispose() => _controller.close();
}
