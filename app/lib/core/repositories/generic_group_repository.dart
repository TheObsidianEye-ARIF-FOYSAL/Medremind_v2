import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/generic_group.dart';

/// Reads the bundled JSON seed. No database table needed — this data is
/// read-only and ships with the app. A real backend can be swapped in later
/// by implementing the same interface.
class GenericGroupRepository {
  List<GenericGroup>? _cache;

  Future<List<GenericGroup>> getAll() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<GenericGroup?> findByBrand(String brandName) async {
    final all = await getAll();
    final query = brandName.trim().toLowerCase();
    try {
      return all.firstWhere(
        (g) => g.brands.any((b) => b.toLowerCase() == query),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<GenericGroup>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final all = await getAll();
    final q = query.trim().toLowerCase();
    return all
        .where((g) =>
            g.name.toLowerCase().contains(q) ||
            g.brands.any((b) => b.toLowerCase().contains(q)))
        .toList();
  }

  static Future<List<GenericGroup>> _loadFromAsset() async {
    final raw =
        await rootBundle.loadString('assets/generic_groups_seed.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => GenericGroup.fromJson(e as Map<String, dynamic>)).toList();
  }
}
