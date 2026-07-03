import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';

// ── Form state ────────────────────────────────────────────────────────────────

class AddMedicineFormState {
  final String brandName;
  final MedicineForm form;
  final String strength;
  final bool isSaving;
  final String? error;
  final String? editingId;

  const AddMedicineFormState({
    this.brandName = '',
    this.form = MedicineForm.tablet,
    this.strength = '',
    this.isSaving = false,
    this.error,
    this.editingId,
  });

  AddMedicineFormState copyWith({
    String? brandName,
    MedicineForm? form,
    String? strength,
    bool? isSaving,
    String? error,
    String? editingId,
  }) =>
      AddMedicineFormState(
        brandName: brandName ?? this.brandName,
        form: form ?? this.form,
        strength: strength ?? this.strength,
        isSaving: isSaving ?? this.isSaving,
        error: error ?? this.error,
        editingId: editingId ?? this.editingId,
      );

  bool get isValid => brandName.trim().isNotEmpty;
  bool get isEditing => editingId != null;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AddMedicineFormNotifier extends StateNotifier<AddMedicineFormState> {
  final Ref _ref;
  AddMedicineFormNotifier(this._ref) : super(const AddMedicineFormState());

  void setBrandName(String v) => state = state.copyWith(brandName: v);
  void setForm(MedicineForm f) => state = state.copyWith(form: f);
  void setStrength(String v) => state = state.copyWith(strength: v);

  /// Loads an existing medicine's fields for editing.
  void loadForEdit(Medicine med) {
    state = AddMedicineFormState(
      brandName: med.brandName,
      form: med.form,
      strength: med.strength,
      editingId: med.id,
    );
  }

  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final medRepo = _ref.read(medicineRepositoryProvider);
      if (state.isEditing) {
        final existing = await medRepo.getById(state.editingId!);
        if (existing == null) throw StateError('Medicine not found');
        await medRepo.update(Medicine(
          id: existing.id,
          brandName: state.brandName.trim(),
          genericGroupId: existing.genericGroupId,
          form: state.form,
          strength: state.strength.trim(),
          notes: existing.notes,
        ));
      } else {
        await medRepo.insert(
          brandName: state.brandName.trim(),
          form: state.form,
          strength: state.strength.trim(),
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

final addMedicineFormProvider = StateNotifierProvider.autoDispose<
    AddMedicineFormNotifier, AddMedicineFormState>(
  AddMedicineFormNotifier.new,
);
