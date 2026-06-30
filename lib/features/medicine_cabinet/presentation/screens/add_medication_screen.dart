import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/medicine_cabinet_provider.dart';
import '../widgets/medicine_type_selector.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _brandCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  String? _genericHint;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final groups = await ref.read(genericGroupRepositoryProvider).getAll();
    if (!mounted) return;
    final brands = <String>{};
    for (final g in groups) {
      brands.addAll(g.brands);
    }
    setState(() => _suggestions = brands.toList()..sort());
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _strengthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final form = ref.watch(addMedicineFormProvider);
    final notifier = ref.read(addMedicineFormProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Add Medicine',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // ── Info banner ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add the medicine here. To set reminders, create a Dose Group in the Schedules tab.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: primary),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Medicine name ──────────────────────────────────────
                  _Label('Medicine Name'),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue v) {
                      if (v.text.length < 2) return const Iterable.empty();
                      final q = v.text.toLowerCase();
                      return _suggestions
                          .where((s) => s.toLowerCase().contains(q))
                          .take(6);
                    },
                    displayStringForOption: (s) => s,
                    fieldViewBuilder:
                        (ctx, ctrl, focusNode, onSubmit) {
                      // Keep our controller in sync
                      ctrl.text = _brandCtrl.text;
                      ctrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: ctrl.text.length));
                      return TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Napa, Vigorex 25mg, Amlodipine',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: primary, size: 20),
                          suffixIcon: form.brandName.isNotEmpty
                              ? const Icon(Icons.check_circle_rounded,
                                  color: TagColors.taken)
                              : null,
                        ),
                        onChanged: (val) {
                          _brandCtrl.text = val;
                          notifier.setBrandName(val);
                          _lookupGeneric(val);
                        },
                        onEditingComplete: onSubmit,
                      );
                    },
                    onSelected: (String selection) {
                      _brandCtrl.text = selection;
                      notifier.setBrandName(selection);
                      _lookupGeneric(selection);
                    },
                    optionsViewBuilder: (ctx, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final opt = options.elementAt(i);
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.local_pharmacy_outlined,
                                      size: 16, color: primary),
                                  title: Text(opt,
                                      style: Theme.of(ctx).textTheme.bodyMedium),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Generic hint
                  if (_genericHint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [
                        Icon(Icons.local_pharmacy_outlined,
                            size: 14, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          'Generic: $_genericHint',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: primary),
                        ),
                      ]),
                    ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Strength ───────────────────────────────────────────
                  _Label('Strength (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _strengthCtrl,
                    decoration: const InputDecoration(
                        hintText: 'e.g. 500mg, 10mg, 25mg'),
                    onChanged: notifier.setStrength,
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Medicine type ──────────────────────────────────────
                  _Label('Type'),
                  const SizedBox(height: 8),
                  MedicineTypeSelector(
                    selected: form.form,
                    onChanged: notifier.setForm,
                  ),

                  if (form.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(form.error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: TagColors.missed)),
                    ),

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),

            // ── Save button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.paddingLg, 0,
                  AppSizes.paddingLg, AppSizes.paddingLg),
              child: PillButton(
                label: 'Save Medicine',
                isLoading: form.isSaving,
                onPressed: form.isValid ? () => _save(context) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lookupGeneric(String brand) async {
    if (brand.length < 2) {
      setState(() => _genericHint = null);
      return;
    }
    final group =
        await ref.read(genericGroupRepositoryProvider).findByBrand(brand);
    if (mounted) setState(() => _genericHint = group?.name);
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final ok = await ref.read(addMedicineFormProvider.notifier).save();
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Medicine saved!')),
      );
      nav.pop();
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600));
}
