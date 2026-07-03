/// Medicine form types (matches the icon selector in Add Medication screen).
enum MedicineForm { tablet, pill, syrup, syringe, other }

/// A medicine in the user's personal cabinet.
class Medicine {
  final String id;
  final String brandName;
  final String? genericGroupId;
  final MedicineForm form;
  final String strength; // e.g. "500mg"
  final String? notes;

  const Medicine({
    required this.id,
    required this.brandName,
    this.genericGroupId,
    this.form = MedicineForm.tablet,
    this.strength = '',
    this.notes,
  });

  Medicine copyWith({
    String? brandName,
    String? genericGroupId,
    MedicineForm? form,
    String? strength,
    String? notes,
  }) =>
      Medicine(
        id: id,
        brandName: brandName ?? this.brandName,
        genericGroupId: genericGroupId ?? this.genericGroupId,
        form: form ?? this.form,
        strength: strength ?? this.strength,
        notes: notes ?? this.notes,
      );
}
