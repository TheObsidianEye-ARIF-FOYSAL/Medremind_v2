import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../reminders/presentation/screens/time_picker_screen.dart';
import '../widgets/med_row_widget.dart';
import '../widgets/medicine_picker_sheet.dart';

// ── Label presets ─────────────────────────────────────────────────────────────

const _labels = [
  ('Morning', TagColors.morning, Icons.wb_sunny_rounded),
  ('Afternoon', TagColors.afternoon, Icons.wb_cloudy_rounded),
  ('Evening', TagColors.evening, Icons.nights_stay_outlined),
  ('Night', TagColors.night, Icons.nightlight_round),
];

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
  // empty = every day; 1=Mon … 7=Sun (DateTime.weekday convention)
  List<int> _days = [];
  final List<MedSlot> _slots = [];
  bool _saving = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final labelColor = _labels
        .firstWhere((l) => l.$1 == _label, orElse: () => _labels.first)
        .$2;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
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
              child: Row(children: [
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _slots.isNotEmpty
                      ? FilledButton(
                          key: const ValueKey('save'),
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
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ]),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // ── Dose time label selector ──────────────────────
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
                              final defaults = {
                                'Morning': const TimeOfDay(hour: 8, minute: 0),
                                'Afternoon':
                                    const TimeOfDay(hour: 13, minute: 0),
                                'Evening':
                                    const TimeOfDay(hour: 18, minute: 0),
                                'Night': const TimeOfDay(hour: 21, minute: 0),
                              };
                              if (defaults.containsKey(l.$1)) {
                                setState(() => _time = defaults[l.$1]!);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
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
                              child: Column(children: [
                                Icon(l.$3,
                                    size: 20,
                                    color: sel
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant),
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
                              ]),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Alarm time picker ────────────────────────────────
                  Text('Alarm Time',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: AppSizes.paddingSm),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.surface : LightColors.surface,
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

                  // ── Meal relation ────────────────────────────────────
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

                  const SizedBox(height: AppSizes.paddingLg),

                  // ── Days of week ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Repeat Days',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () => setState(() => _days = []),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _days.isEmpty
                                ? primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill),
                            border: Border.all(
                              color: _days.isEmpty
                                  ? primary.withValues(alpha: 0.5)
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            'Every day',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _days.isEmpty
                                  ? primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: _days.isEmpty
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  Row(
                    children: List.generate(7, (i) {
                      final dayNum = i + 1; // 1=Mon … 7=Sun
                      final sel = _days.contains(dayNum);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (sel) {
                                  _days = _days
                                      .where((d) => d != dayNum)
                                      .toList();
                                } else {
                                  _days = [..._days, dayNum]..sort();
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 40,
                              decoration: BoxDecoration(
                                color: sel
                                    ? primary
                                    : (isDark
                                        ? DarkColors.surfaceVariant
                                        : LightColors.surfaceVariant),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: primary
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  _dayLabels[i],
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(
                                    color: sel
                                        ? Colors.white
                                        : theme.colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_days.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _days.map((d) => _dayNames[d - 1]).join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: primary, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Medicines in group ───────────────────────────────
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
                                : LightColors.outlineVariant),
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
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.paddingSm),
                        child: MedRowWidget(
                          slot: slot,
                          isDark: isDark,
                          primary: primary,
                          labelColor: labelColor,
                          onQuantityChanged: (q) =>
                              setState(() => slot.quantity = q),
                          onRemove: () => setState(() => _slots.removeAt(i)),
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
        builder: (_) => TimePickerScreen(initial: _time, label: _label),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _time = result;
        _label = _labelFromHour(result.hour);
      });
    }
  }

  static String _labelFromHour(int h) {
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }

  Future<void> _pickMedicine() async {
    final meds = await ref.read(medicineRepositoryProvider).getAll();
    if (!mounted) return;

    final added = _slots.map((s) => s.med.id).toSet();
    final available = meds.where((m) => !added.contains(m.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All your medicines are already in this group.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MedicinePickerSheet(medicines: available),
    );

    if (picked != null && mounted) {
      setState(() => _slots.add(MedSlot(med: picked, quantity: 1)));
    }
  }

  Future<void> _save() async {
    if (_slots.isEmpty) return;
    setState(() => _saving = true);

    final h = _time.hour.toString().padLeft(2, '0');
    final m = _time.minute.toString().padLeft(2, '0');

    try {
      final repo = ref.read(doseGroupRepositoryProvider);
      final group = await repo.insert(
        label: _label,
        timeOfDay: '$h:$m',
        mealRelation: _meal,
        daysOfWeek: _days,
        startDate: DateTime.now(),
        items: _slots
            .map((s) => (medicineId: s.med.id, quantity: s.quantity))
            .toList(),
      );
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
