/// A generic drug group (e.g. Paracetamol) with its known brand list.
class GenericGroup {
  final String id;
  final String name;           // e.g. "Paracetamol"
  final String? description;
  final List<String> brands;   // brand names in the seed dataset

  const GenericGroup({
    required this.id,
    required this.name,
    this.description,
    this.brands = const [],
  });

  factory GenericGroup.fromJson(Map<String, dynamic> json) => GenericGroup(
        id: json['generic'] as String,
        name: json['generic'] as String,
        description: json['description'] as String?,
        brands: List<String>.from(json['brands'] as List),
      );
}
