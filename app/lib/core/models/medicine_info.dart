/// A brand-name medicine entry from the bundled Bangladesh medicine dataset.
class BrandInfo {
  final String brand;
  final String generic;
  final String strength;
  final String form;
  final String manufacturer;

  const BrandInfo({
    required this.brand,
    required this.generic,
    required this.strength,
    required this.form,
    required this.manufacturer,
  });
}

/// Clinical info for a generic ingredient, from the bundled dataset.
class GenericInfo {
  final String name;
  final String drugClass;
  final String indication;
  final String indicationDescription;
  final String pharmacologyDescription;
  final String dosageDescription;
  final String sideEffectsDescription;
  final String precautionsDescription;
  final String contraindicationsDescription;

  const GenericInfo({
    required this.name,
    required this.drugClass,
    required this.indication,
    required this.indicationDescription,
    required this.pharmacologyDescription,
    required this.dosageDescription,
    required this.sideEffectsDescription,
    required this.precautionsDescription,
    required this.contraindicationsDescription,
  });
}
