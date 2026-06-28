import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';

// ── Slot state: one time-of-day entry in the Add Medication form ──────────────
class DoseSlot {
  final String label;
  final String timeOfDay;   // "HH:mm"
  final double quantity;
  final MealRelation mealRelation;

  const DoseSlot({
    required this.label,
    required this.timeOfDay,
    this.quantity = 1,
    this.mealRelation = MealRelation.none,
  });

  DoseSlot copyWith({
    String? label,
    String? timeOfDay,
    double? quantity,
    MealRelation? mealRelation,
  }) =>
      DoseSlot(
        label: label ?? this.label,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        quantity: quantity ?? this.quantity,
        mealRelation: mealRelation ?? this.mealRelation,
      );
}

// ── Form state ────────────────────────────────────────────────────────────────
class AddMedicineFormState {
  final String brandName;
  final MedicineForm form;
  final String strength;
  final List<DoseSlot> slots;
  final bool isSaving;
  final String? error;

  const AddMedicineFormState({
    this.brandName = '',
    this.form = MedicineForm.tablet,
    this.strength = '',
    this.slots = const [],
    this.isSaving = false,
    this.error,
  });

  AddMedicineFormState copyWith({
    String? brandName,
    MedicineForm? form,
    String? strength,
    List<DoseSlot>? slots,
    bool? isSaving,
    String? error,
  }) =>
      AddMedicineFormState(
        brandName: brandName ?? this.brandName,
        form: form ?? this.form,
        strength: strength ?? this.strength,
        slots: slots ?? this.slots,
        isSaving: isSaving ?? this.isSaving,
        error: error ?? this.error,
      );

  bool get isValid => brandName.trim().isNotEmpty && slots.isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AddMedicineFormNotifier extends StateNotifier<AddMedicineFormState> {
  final Ref _ref;

  AddMedicineFormNotifier(this._ref) : super(const AddMedicineFormState()) {
    _addDefaultSlots();
  }

  void _addDefaultSlots() {
    state = state.copyWith(slots: [
      const DoseSlot(label: 'Morning', timeOfDay: '08:00'),
    ]);
  }

  void setBrandName(String v) => state = state.copyWith(brandName: v);
  void setForm(MedicineForm f) => state = state.copyWith(form: f);
  void setStrength(String v) => state = state.copyWith(strength: v);

  void updateSlot(int index, DoseSlot updated) {
    final slots = [...state.slots];
    slots[index] = updated;
    state = state.copyWith(slots: slots);
  }

  void addSlot() {
    final labels = ['Morning', 'Afternoon', 'Night', 'Custom'];
    final used = state.slots.map((s) => s.label).toSet();
    final label = labels.firstWhere(
      (l) => !used.contains(l),
      orElse: () => 'Custom ${state.slots.length + 1}',
    );
    final defaultTimes = {
      'Morning': '08:00',
      'Afternoon': '14:00',
      'Night': '21:00',
    };
    state = state.copyWith(
      slots: [
        ...state.slots,
        DoseSlot(
          label: label,
          timeOfDay: defaultTimes[label] ?? '12:00',
        ),
      ],
    );
  }

  void removeSlot(int index) {
    if (state.slots.length <= 1) return;
    final slots = [...state.slots]..removeAt(index);
    state = state.copyWith(slots: slots);
  }

  /// Save medicine + all dose groups to the DB.
  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final medRepo = _ref.read(medicineRepositoryProvider);
      final dgRepo = _ref.read(doseGroupRepositoryProvider);

      final medicine = await medRepo.insert(
        brandName: state.brandName.trim(),
        form: state.form,
        strength: state.strength.trim(),
      );

      for (final slot in state.slots) {
        await dgRepo.insert(
          label: slot.label,
          timeOfDay: slot.timeOfDay,
          mealRelation: slot.mealRelation,
          startDate: DateTime.now(),
          items: [(medicineId: medicine.id, quantity: slot.quantity)],
        );
      }
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const AddMedicineFormState();
}

final addMedicineFormProvider =
    StateNotifierProvider.autoDispose<AddMedicineFormNotifier, AddMedicineFormState>(
  AddMedicineFormNotifier.new,
);
