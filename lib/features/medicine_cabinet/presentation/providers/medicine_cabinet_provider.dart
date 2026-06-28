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

  const AddMedicineFormState({
    this.brandName = '',
    this.form = MedicineForm.tablet,
    this.strength = '',
    this.isSaving = false,
    this.error,
  });

  AddMedicineFormState copyWith({
    String? brandName,
    MedicineForm? form,
    String? strength,
    bool? isSaving,
    String? error,
  }) =>
      AddMedicineFormState(
        brandName: brandName ?? this.brandName,
        form: form ?? this.form,
        strength: strength ?? this.strength,
        isSaving: isSaving ?? this.isSaving,
        error: error ?? this.error,
      );

  bool get isValid => brandName.trim().isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AddMedicineFormNotifier extends StateNotifier<AddMedicineFormState> {
  final Ref _ref;
  AddMedicineFormNotifier(this._ref) : super(const AddMedicineFormState());

  void setBrandName(String v) => state = state.copyWith(brandName: v);
  void setForm(MedicineForm f) => state = state.copyWith(form: f);
  void setStrength(String v) => state = state.copyWith(strength: v);

  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final medRepo = _ref.read(medicineRepositoryProvider);
      await medRepo.insert(
        brandName: state.brandName.trim(),
        form: state.form,
        strength: state.strength.trim(),
      );
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
