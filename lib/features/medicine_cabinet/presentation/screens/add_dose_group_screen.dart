import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../reminders/presentation/screens/time_picker_screen.dart';

// ── Label presets ─────────────────────────────────────────────────────────────

const _labels = [
  ('Morning', TagColors.morning, Icons.wb_sunny_rounded),
  ('Afternoon', TagColors.afternoon, Icons.wb_cloudy_rounded),
  ('Evening', TagColors.evening, Icons.nights_stay_outlined),
  ('Night', TagColors.night, Icons.nightlight_round),
];

// ── Medicine slot in the group ────────────────────────────────────────────────

class _MedSlot {
  final Medicine med;
  double quantity;
  _MedSlot({required this.med, required this.quantity});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AddDoseGroupScreen extends ConsumerStatefulWidget {
  const AddDoseGroupScreen({super.key});

  @override
  ConsumerState<AddDoseGroupScreen> createState() =>
      _AddDoseGroupScreenState();
}

class _AddDoseGroupScreenState extends ConsumerState<AddDoseGroupScreen> {
  String _label = 'Morning';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  MealRelation _meal = MealRelation.none;
  final List<_MedSlot> _slots = [];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final labelColor = _labels
        .firstWhere((l) => l.$1 == _label,
            orElse: () => _labels.first)
        .$2;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd, AppSizes.paddingMd,
                  AppSizes.paddingMd, AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.surface : LightColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New Dose Group',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_slots.isNotEmpty)
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save'),
                    ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // Label selector
                  Text('Dose Time',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSizes.paddingSm),
                  Row(
                    children: _labels.map((l) {
                      final sel = l.$1 == _label;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _label = l.$1);
                              // Auto-fill time
                              final defaults = {
                                'Morning': const TimeOfDay(hour: 8, minute: 0),
                                'Afternoon': const TimeOfDay(hour: 13, minute: 0),
                                'Evening': const TimeOfDay(hour: 18, minute: 0),
                                'Night': const TimeOfDay(hour: 21, minute: 0),
                              };
                              if (defaults.containsKey(l.$1)) {
                                setState(() => _time = defaults[l.$1]!);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? l.$2
                                    : (isDark
                                        ? DarkColors.surfaceVariant
                                        : LightColors.surfaceVariant),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: l.$2.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(l.$3,
                                      size: 20,
                                      color: sel
                                          ? Colors.white
                                          : theme.colorScheme
                                              .onSurfaceVariant),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.$1,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: sel
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Time picker
                  Text('Alarm Time',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSizes.paddingSm),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color:
                            isDark ? DarkColors.surface : LightColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: labelColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Icon(Icons.access_time_rounded,
                              color: labelColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmtTime(_time),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        Text('Tap to change',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18),
                      ]),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // Meal relation
                  Text('Meal Relation',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSizes.paddingSm),
                  Row(children: [
                    for (final (rel, label, icon) in [
                      (MealRelation.none, 'No preference', Icons.block_rounded),
                      (MealRelation.beforeMeal, 'Before meal',
                          Icons.restaurant_rounded),
                      (MealRelation.afterMeal, 'After meal',
                          Icons.local_dining_rounded),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _meal = rel),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _meal == rel
                                    ? primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? DarkColors.surfaceVariant
                                        : LightColors.surfaceVariant),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                                border: _meal == rel
                                    ? Border.all(
                                        color: primary.withValues(alpha: 0.5))
                                    : null,
                              ),
                              child: Column(children: [
                                Icon(icon,
                                    size: 18,
                                    color: _meal == rel
                                        ? primary
                                        : theme.colorScheme.onSurfaceVariant),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _meal == rel
                                        ? primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: _meal == rel
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ]),

                  const SizedBox(height: AppSizes.paddingXl),

                  // Medicines in group
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medicines in this group (${_slots.length})',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add'),
                        onPressed: _pickMedicine,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  if (_slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingLg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.surfaceVariant
                            : LightColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(
                            color: isDark
                                ? DarkColors.outlineVariant
                                : LightColors.outlineVariant,
                            style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.medication_liquid_rounded,
                              size: 36,
                              color: primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'No medicines added yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add" to add medicines to this group',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      ),
                    )
                  else
                    ...List.generate(_slots.length, (i) {
                      final slot = _slots[i];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppSizes.paddingSm),
                        child: _MedRow(
                          slot: slot,
                          isDark: isDark,
                          primary: primary,
                          labelColor: labelColor,
                          onQuantityChanged: (q) =>
                              setState(() => slot.quantity = q),
                          onRemove: () =>
                              setState(() => _slots.removeAt(i)),
                        ),
                      );
                    }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final result = await Navigator.of(context).push<TimeOfDay>(
      MaterialPageRoute(
        builder: (_) => TimePickerScreen(
          initial: _time,
          label: _label,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _time = result);
    }
  }

  Future<void> _pickMedicine() async {
    final meds = await ref.read(medicineRepositoryProvider).getAll();
    if (!mounted) return;

    // Filter out already added medicines
    final added = _slots.map((s) => s.med.id).toSet();
    final available = meds.where((m) => !added.contains(m.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All your medicines are already in this group.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<Medicine>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MedicinePickerSheet(medicines: available),
    );

    if (picked != null && mounted) {
      setState(() => _slots.add(_MedSlot(med: picked, quantity: 1)));
    }
  }

  Future<void> _save() async {
    if (_slots.isEmpty) return;
    setState(() => _saving = true);

    final h = _time.hour.toString().padLeft(2, '0');
    final m = _time.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    try {
      final repo = ref.read(doseGroupRepositoryProvider);
      final group = await repo.insert(
        label: _label,
        timeOfDay: timeStr,
        mealRelation: _meal,
        startDate: DateTime.now(),
        items: _slots
            .map((s) => (medicineId: s.med.id, quantity: s.quantity))
            .toList(),
      );
      // Auto-schedule the alarm for this group
      await alarmService.scheduleForGroup(group);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static String _fmtTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:$m $per';
  }
}

// ── Medicine row inside the group ─────────────────────────────────────────────

class _MedRow extends StatelessWidget {
  final _MedSlot slot;
  final bool isDark;
  final Color primary;
  final Color labelColor;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const _MedRow({
    required this.slot,
    required this.isDark,
    required this.primary,
    required this.labelColor,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border(
          left: BorderSide(color: labelColor, width: 3),
        ),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(Icons.medication_rounded, color: labelColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.med.brandName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (slot.med.strength.isNotEmpty)
                Text(slot.med.strength,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        // Quantity stepper
        Row(children: [
          _QtyBtn(
            icon: Icons.remove_rounded,
            onTap: slot.quantity > 0.5
                ? () => onQuantityChanged(slot.quantity - 0.5)
                : null,
            primary: primary,
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _qty(slot.quantity),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _QtyBtn(
            icon: Icons.add_rounded,
            onTap: slot.quantity < 10
                ? () => onQuantityChanged(slot.quantity + 0.5)
                : null,
            primary: primary,
            isDark: isDark,
          ),
        ]),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
        ),
      ]),
    );
  }

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color primary;
  final bool isDark;
  const _QtyBtn(
      {required this.icon,
      required this.onTap,
      required this.primary,
      required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: onTap != null
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 14,
              color: onTap != null
                  ? primary
                  : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

// ── Medicine picker bottom sheet ──────────────────────────────────────────────

class _MedicinePickerSheet extends StatefulWidget {
  final List<Medicine> medicines;
  const _MedicinePickerSheet({required this.medicines});

  @override
  State<_MedicinePickerSheet> createState() =>
      _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<_MedicinePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final filtered = widget.medicines
        .where((m) =>
            m.brandName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusCard)),
      ),
      child: Column(children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.outline : LightColors.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, AppSizes.paddingMd,
              AppSizes.paddingLg, 0),
          child: Row(children: [
            Expanded(
              child: Text('Select Medicine',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLg, vertical: AppSizes.paddingSm),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search medicines…',
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No medicines found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, AppSizes.paddingSm,
                      AppSizes.paddingLg, 40),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingXs),
                  itemBuilder: (ctx, i) {
                    final m = filtered[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(Icons.medication_rounded,
                            color: primary, size: 20),
                      ),
                      title: Text(m.brandName,
                          style: theme.textTheme.titleSmall),
                      subtitle: m.strength.isNotEmpty
                          ? Text(m.strength)
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkColors.surfaceVariant
                              : LightColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(m.form.name,
                            style: theme.textTheme.labelSmall),
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
