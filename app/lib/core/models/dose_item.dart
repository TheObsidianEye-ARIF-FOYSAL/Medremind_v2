/// One medicine inside a DoseGroup (e.g. 2 tablets of Napa).
class DoseItem {
  final String id;
  final String doseGroupId;
  final String medicineId;
  final double quantity;   // e.g. 1.5 = 1½ tablets

  const DoseItem({
    required this.id,
    required this.doseGroupId,
    required this.medicineId,
    this.quantity = 1,
  });
}
