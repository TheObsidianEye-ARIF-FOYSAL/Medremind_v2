import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';

// ── Calendar stat chip ─────────────────────────────────────────────────────────

class CalendarStatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const CalendarStatChip({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        '$count $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Calendar stats card ────────────────────────────────────────────────────────

class CalendarStatsCard extends StatelessWidget {
  final DateTime date;
  final ({int total, int taken, int skipped, int missed, int pending}) stats;
  final bool isDark;
  final Color primary;

  const CalendarStatsCard({
    super.key,
    required this.date,
    required this.stats,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final pct = stats.total > 0
        ? (stats.taken / stats.total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        // Progress ring
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: pct,
              backgroundColor: primary.withValues(alpha: 0.1),
              color: pct == 1.0 ? TagColors.taken : primary,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
            Text(
              '${(pct * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: pct == 1.0 ? TagColors.taken : primary,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? "Today's Summary" : _fmtDate(date),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(children: [
                CalendarStatChip(count: stats.taken, label: 'Taken', color: TagColors.taken),
                const SizedBox(width: 6),
                if (stats.pending > 0)
                  CalendarStatChip(count: stats.pending, label: 'Pending', color: TagColors.pending),
                if (stats.pending > 0) const SizedBox(width: 6),
                if (stats.missed > 0)
                  CalendarStatChip(count: stats.missed, label: 'Missed', color: TagColors.missed),
                if (stats.missed > 0) const SizedBox(width: 6),
                if (stats.skipped > 0)
                  CalendarStatChip(count: stats.skipped, label: 'Skipped', color: TagColors.skipped),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
