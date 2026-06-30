import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/calendar_provider.dart';

// ── Calendar day cell ──────────────────────────────────────────────────────────

class CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final CalendarDayStatus status;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final ThemeData theme;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.status,
    required this.primary,
    required this.isDark,
    required this.onTap,
    required this.theme,
  });

  Color get _dotColor {
    if (isSelected) return Colors.white;
    return switch (status) {
      CalendarDayStatus.taken => TagColors.taken,
      CalendarDayStatus.partial => TagColors.snoozed,
      CalendarDayStatus.missed => TagColors.missed,
      CalendarDayStatus.scheduled => primary.withValues(alpha: 0.6),
      CalendarDayStatus.none => Colors.transparent,
    };
  }

  bool get _hasDot => status != CalendarDayStatus.none;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? primary
        : isToday
            ? primary.withValues(alpha: 0.18)
            : Colors.transparent;

    final textColor = isSelected
        ? Colors.white
        : isToday
            ? primary
            : theme.colorScheme.onSurface;

    // Border for today (if not selected)
    final Border? border = !isSelected && isToday
        ? Border.all(color: primary, width: 1.5)
        : (!isSelected && (status == CalendarDayStatus.taken ||
                status == CalendarDayStatus.partial))
            ? Border.all(
                color: status == CalendarDayStatus.taken
                    ? TagColors.taken.withValues(alpha: 0.35)
                    : TagColors.snoozed.withValues(alpha: 0.35),
                width: 1)
            : null;

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: border,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight:
                        isToday || isSelected || _hasDot
                            ? FontWeight.w700
                            : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: status == CalendarDayStatus.partial ? 6 : 4,
              height: status == CalendarDayStatus.partial ? 4 : 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasDot ? _dotColor : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar month grid ────────────────────────────────────────────────────────

class CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Map<int, CalendarDayStatus> dayStatuses;
  final bool isDark;
  final Color primary;
  final ValueChanged<DateTime> onDayTap;

  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.dayStatuses,
    required this.isDark,
    required this.primary,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    final firstDay = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        CalendarDayCell(
          day: d,
          isToday: today.year == month.year &&
              today.month == month.month &&
              today.day == d,
          isSelected: selectedDate.year == month.year &&
              selectedDate.month == month.month &&
              selectedDate.day == d,
          status: dayStatuses[d] ?? CalendarDayStatus.none,
          primary: primary,
          isDark: isDark,
          onTap: () => onDayTap(DateTime(month.year, month.month, d)),
          theme: theme,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}
