import 'package:flutter/material.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/theme/theme_constants.dart';

// ── Dose status icon ───────────────────────────────────────────────────────────

class DoseStatusIcon extends StatelessWidget {
  final DoseStatus status;
  const DoseStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (c, ic) = switch (status) {
      DoseStatus.taken => (TagColors.taken, Icons.check_circle_rounded),
      DoseStatus.skipped => (TagColors.skipped, Icons.cancel_rounded),
      DoseStatus.missed => (TagColors.missed, Icons.error_rounded),
      DoseStatus.snoozed => (TagColors.snoozed, Icons.snooze_rounded),
      _ => (TagColors.pending, Icons.pending_rounded),
    };
    return Icon(ic, color: c, size: 20);
  }
}

// ── Dose action button ─────────────────────────────────────────────────────────

class DoseActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const DoseActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Dose card ──────────────────────────────────────────────────────────────────

class DoseCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  final bool isDark;
  final Color primary;
  final VoidCallback onTaken, onSkip, onSnooze;

  const DoseCard({
    super.key,
    required this.resolved,
    required this.isDark,
    required this.primary,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
  });

  static const _lc = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Evening': TagColors.evening,
    'Night': TagColors.night,
  };

  static const _fi = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = resolved.group;
    final lc = _lc[group.label] ?? primary;
    final taken = resolved.isTaken;
    final pending = resolved.isPending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: taken
            ? lc.withValues(alpha: isDark ? 0.12 : 0.07)
            : (isDark ? DarkColors.surface : LightColors.surface),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(
          left: BorderSide(
            color: taken ? lc.withValues(alpha: 0.5) : lc,
            width: 4,
          ),
        ),
        boxShadow: taken
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(group.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: lc, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(
                _fmt(group.timeOfDay),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!pending) ...[
                const SizedBox(width: 8),
                DoseStatusIcon(status: resolved.status),
              ],
            ]),
          ),

          Divider(
            height: 1,
            color: isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
          ),

          // Medicine rows
          ...resolved.items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: lc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                            color: lc.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Icon(_fi[item.form] ?? Icons.medication_rounded,
                        size: 20, color: lc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicineName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration:
                                taken ? TextDecoration.lineThrough : null,
                            decorationColor:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(children: [
                          Text(
                            '${_qty(item.quantity)} ${item.form.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (group.mealRelation != MealRelation.none) ...[
                            Text(' · ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            Text(
                              _meal(group.mealRelation),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: lc.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ]),
              )),

          // Actions
          if (!taken) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 42,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [lc, lc.withValues(alpha: 0.75)]),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                        boxShadow: [
                          BoxShadow(
                              color: lc.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onTaken,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Taken'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DoseActionBtn(
                    icon: Icons.snooze_rounded,
                    label: 'Snooze',
                    color: TagColors.snoozed,
                    onTap: onSnooze),
                const SizedBox(width: 8),
                DoseActionBtn(
                    icon: Icons.close_rounded,
                    label: 'Skip',
                    color: TagColors.missed,
                    onTap: onSkip),
              ]),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  static String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $per';
  }

  static String _meal(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => 'Before meal',
        MealRelation.afterMeal => 'After meal',
        _ => '',
      };

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}
