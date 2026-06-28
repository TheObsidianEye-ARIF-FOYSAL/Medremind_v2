import 'package:flutter/material.dart';
import '../../theme/theme_constants.dart';

/// Horizontal 7-day calendar strip (Image 4 bottom of home screen).
/// Shows the current week; highlights today and days with doses.
class MiniCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Set<DateTime> daysWithDoses;
  final ValueChanged<DateTime>? onDayTap;

  const MiniCalendarStrip({
    super.key,
    required this.selectedDate,
    this.daysWithDoses = const {},
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final today = DateTime.now();

    // Show a 7-day window centred on today.
    final start = today.subtract(const Duration(days: 3));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _monthLabel(today),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Day cells
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = days[i];
            final isToday = _sameDay(day, today);
            final isSelected = _sameDay(day, selectedDate);
            final hasDoses = daysWithDoses
                .any((d) => _sameDay(d, day));

            return _DayCell(
              label: dayLabels[(day.weekday - 1) % 7],
              dayNum: day.day,
              isToday: isToday,
              isSelected: isSelected,
              hasDoses: hasDoses,
              primary: primary,
              isDark: isDark,
              onTap: () => onDayTap?.call(day),
            );
          }),
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final int dayNum;
  final bool isToday;
  final bool isSelected;
  final bool hasDoses;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _DayCell({
    required this.label,
    required this.dayNum,
    required this.isToday,
    required this.isSelected,
    required this.hasDoses,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected || isToday
        ? primary
        : (isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant);
    final textColor = isSelected || isToday
        ? Colors.white
        : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  dayNum.toString(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Dot for days with doses
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasDoses
                    ? (isSelected || isToday
                        ? Colors.white.withValues(alpha: 0.8)
                        : primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
