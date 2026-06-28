import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/medicine_cabinet_provider.dart';
import '../widgets/dose_stepper.dart';
import '../widgets/meal_relation_chip.dart';
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
  bool _showGenericHint = false;
  String? _genericHint;

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
    final form = ref.watch(addMedicineFormProvider);
    final notifier = ref.read(addMedicineFormProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Add medication',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // Brand name input
                  _SectionLabel('Medicine Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Napa, Amlodipine 5mg',
                      suffixIcon: form.brandName.isNotEmpty
                          ? const Icon(Icons.check_circle_rounded,
                              color: TagColors.taken)
                          : null,
                    ),
                    onChanged: (v) {
                      notifier.setBrandName(v);
                      _lookupGeneric(v);
                    },
                  ),

                  // Generic hint
                  if (_showGenericHint && _genericHint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Generic: $_genericHint',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Strength
                  _SectionLabel('Strength (optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _strengthCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. 500mg'),
                    onChanged: notifier.setStrength,
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Medicine type
                  _SectionLabel('Type'),
                  const SizedBox(height: 8),
                  MedicineTypeSelector(
                    selected: form.form,
                    onChanged: notifier.setForm,
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Frequency section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('Pills Frequency'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkColors.surfaceVariant
                              : LightColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Row(
                          children: [
                            Text('Per day',
                                style: theme.textTheme.labelSmall),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Time slots
                  ...form.slots.asMap().entries.map((entry) {
                    final i = entry.key;
                    final slot = entry.value;
                    return _TimeSlotCard(
                      slot: slot,
                      isDark: isDark,
                      onUpdate: (updated) => notifier.updateSlot(i, updated),
                      onRemove: form.slots.length > 1
                          ? () => notifier.removeSlot(i)
                          : null,
                      onPickTime: () => _pickTime(context, i, slot),
                    );
                  }),

                  // Add slot button
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: notifier.addSlot,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? DarkColors.outline
                              : LightColors.outline,
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Add another time',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              )),
                        ],
                      ),
                    ),
                  ),

                  if (form.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        form.error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: TagColors.missed),
                      ),
                    ),

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, 0,
                  AppSizes.paddingLg, AppSizes.paddingLg),
              child: PillButton(
                label: 'Add to Pill list',
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
      setState(() {
        _showGenericHint = false;
        _genericHint = null;
      });
      return;
    }
    final repo = ref.read(genericGroupRepositoryProvider);
    final group = await repo.findByBrand(brand);
    if (mounted) {
      setState(() {
        _genericHint = group?.name;
        _showGenericHint = group != null;
      });
    }
  }

  Future<void> _pickTime(BuildContext context, int index, DoseSlot slot) async {
    final parts = slot.timeOfDay.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    // Push the custom circular time picker
    final picked = await Navigator.of(context).push<TimeOfDay>(
      MaterialPageRoute(
        builder: (_) => _SimpleTimePicker(initial: initial),
      ),
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      ref.read(addMedicineFormProvider.notifier)
          .updateSlot(index, slot.copyWith(timeOfDay: '$h:$m'));
    }
  }

  Future<void> _save(BuildContext context) async {
    final notifier = ref.read(addMedicineFormProvider.notifier);
    final ok = await notifier.save();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully!')),
      );
      Navigator.of(context).pop();
    }
  }
}

// ── Slot card ─────────────────────────────────────────────────────────────────

class _TimeSlotCard extends StatelessWidget {
  final DoseSlot slot;
  final bool isDark;
  final ValueChanged<DoseSlot> onUpdate;
  final VoidCallback? onRemove;
  final VoidCallback onPickTime;

  const _TimeSlotCard({
    required this.slot,
    required this.isDark,
    required this.onUpdate,
    this.onRemove,
    required this.onPickTime,
  });

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Night': TagColors.night,
    'Evening': TagColors.evening,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = _labelColors[slot.label] ?? theme.colorScheme.primary;
    final emoji = switch (slot.label) {
      'Morning' => '☀️',
      'Afternoon' => '🌤️',
      'Night' => '🌙',
      'Evening' => '🌆',
      _ => '⏰',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Text(
                '$emoji ${slot.label}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: labelColor),
              ),
              const Spacer(),
              // Time tap target
              GestureDetector(
                onTap: onPickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(slot.timeOfDay),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      color: TagColors.missed, size: 20),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Dose stepper
          DoseStepper(
            value: slot.quantity,
            onChanged: (v) => onUpdate(slot.copyWith(quantity: v)),
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Meal relation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: MealRelationPicker(
              selected: slot.mealRelation,
              onChanged: (r) => onUpdate(slot.copyWith(mealRelation: r)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }
}

// ── Minimal inline time picker (replaced by CircularTimePicker route) ─────────
class _SimpleTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  const _SimpleTimePicker({required this.initial});

  @override
  State<_SimpleTimePicker> createState() => _SimpleTimePickerState();
}

class _SimpleTimePickerState extends State<_SimpleTimePicker> {
  late TimeOfDay _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    // Delegate to the real CircularTimePickerScreen defined in Phase 3.
    // For now show a Material time picker as a fallback.
    return Scaffold(
      appBar: AppBar(title: const Text('Select Time')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_selected.hour.toString().padLeft(2, '0')} : ${_selected.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final picked = await showTimePicker(
                    context: context, initialTime: _selected);
                if (picked != null) setState(() => _selected = picked);
              },
              child: const Text('Pick time'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tiny helper ───────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600));
  }
}
