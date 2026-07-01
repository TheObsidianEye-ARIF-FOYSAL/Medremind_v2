import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/medicine_info.dart';

/// Reads the bundled Bangladesh medicine dataset (21k+ brands, 1.6k+
/// generics with clinical info), preprocessed offline from a Kaggle CSV
/// dump into compact JSON assets. Fully offline — no network required.
class MedicineDatasetRepository {
  List<BrandInfo>? _brands;
  Map<String, GenericInfo>? _generics;

  Future<void> _ensureLoaded() async {
    if (_brands != null && _generics != null) return;

    final brandsRaw =
        await rootBundle.loadString('assets/med_dataset/brands.json');
    final brandsList = jsonDecode(brandsRaw) as List;
    _brands = brandsList
        .map((e) => BrandInfo(
              brand: e[0] as String,
              generic: e[1] as String,
              strength: e[2] as String,
              form: e[3] as String,
              manufacturer: e[4] as String,
            ))
        .toList();

    final genericsRaw =
        await rootBundle.loadString('assets/med_dataset/generics.json');
    final genMap = jsonDecode(genericsRaw) as Map<String, dynamic>;
    _generics = genMap.map((k, v) {
      final m = v as Map<String, dynamic>;
      return MapEntry(
        k,
        GenericInfo(
          name: k,
          drugClass: m['c'] as String? ?? '',
          indication: m['i'] as String? ?? '',
          indicationDescription: m['id'] as String? ?? '',
          pharmacologyDescription: m['ph'] as String? ?? '',
          dosageDescription: m['do'] as String? ?? '',
          sideEffectsDescription: m['se'] as String? ?? '',
          precautionsDescription: m['pr'] as String? ?? '',
          contraindicationsDescription: m['co'] as String? ?? '',
        ),
      );
    });
  }

  /// Case-insensitive substring search over brand names, best-match-first.
  Future<List<BrandInfo>> searchBrands(String query, {int limit = 8}) async {
    if (query.trim().length < 2) return [];
    await _ensureLoaded();
    final q = query.trim().toLowerCase();

    final matches = _brands!.where((b) => b.brand.toLowerCase().contains(q)).toList();
    matches.sort((a, b) {
      final aStarts = a.brand.toLowerCase().startsWith(q);
      final bStarts = b.brand.toLowerCase().startsWith(q);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.brand.compareTo(b.brand);
    });
    return matches.take(limit).toList();
  }

  /// Exact (case-insensitive) brand lookup.
  Future<BrandInfo?> findBrand(String brandName) async {
    await _ensureLoaded();
    final q = brandName.trim().toLowerCase();
    for (final b in _brands!) {
      if (b.brand.toLowerCase() == q) return b;
    }
    return null;
  }

  Future<GenericInfo?> getGenericInfo(String genericName) async {
    await _ensureLoaded();
    return _generics![genericName];
  }

  /// Other brands that share the same generic ingredient (excludes [excludeBrand]).
  Future<List<BrandInfo>> brandsForGeneric(String genericName,
      {String? excludeBrand}) async {
    await _ensureLoaded();
    return _brands!
        .where((b) =>
            b.generic == genericName &&
            b.brand.toLowerCase() != (excludeBrand ?? '').toLowerCase())
        .toList();
  }
}

final medicineDatasetRepository = MedicineDatasetRepository();
