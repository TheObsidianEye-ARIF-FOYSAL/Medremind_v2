import 'package:flutter/material.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/theme/theme_constants.dart';

// ── Calendar agenda card ───────────────────────────────────────────────────────

class CalendarAgendaCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  const CalendarAgendaCard({super.key, required this.resolved});

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Night': TagColors.night,
    'Evening': TagColors.evening,
  };

  static const _labelIcons = {
    'Morning': Icons.wb_sunny_rounded,
    'Afternoon': Icons.wb_cloudy_rounded,
    'Evening': Icons.nights_stay_outlined,
    'Night': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final group = resolved.group;
    final labelColor = _labelColors[group.label] ?? primary;
    final labelIcon = _labelIcons[group.label] ?? Icons.schedule_rounded;

    final (statusColor, statusLabel, statusIcon) = switch (resolved.status) {
      DoseStatus.taken => (TagColors.taken, 'Taken', Icons.check_circle_rounded),
      DoseStatus.skipped => (TagColors.skipped, 'Skipped', Icons.cancel_rounded),
      DoseStatus.missed => (TagColors.missed, 'Missed', Icons.error_rounded),
      DoseStatus.snoozed => (TagColors.snoozed, 'Snoozed', Icons.snooze_rounded),
      _ => (TagColors.pending, 'Pending', Icons.radio_button_unchecked_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border(left: BorderSide(color: labelColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Time + label column
        SizedBox(
          width: 68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fmt(group.timeOfDay),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(labelIcon, size: 11, color: labelColor),
                const SizedBox(width: 3),
                Text(group.label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: labelColor, fontSize: 10)),
              ]),
            ],
          ),
        ),

        // Vertical divider
        Container(
          width: 2,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                labelColor,
                labelColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),

        // Medicine info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolved.items.map((i) => i.medicineName).join(', '),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                resolved.items
                    .map((i) => '${_qty(i.quantity)} ${i.form.name}')
                    .join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (group.mealRelation != MealRelation.none)
                Text(
                  group.mealRelation == MealRelation.beforeMeal
                      ? '· Before meal'
                      : '· After meal',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(statusIcon, size: 12, color: statusColor),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ]),
    );
  }

  static String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}\n$period';
  }

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}
