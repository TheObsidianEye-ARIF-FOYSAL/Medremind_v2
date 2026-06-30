import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';

// ── Calendar day cell ──────────────────────────────────────────────────────────

class CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasDoses;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final ThemeData theme;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasDoses,
    required this.primary,
    required this.isDark,
    required this.onTap,
    required this.theme,
  });

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
                border: hasDoses && !isSelected && !isToday
                    ? Border.all(
                        color: primary.withValues(alpha: 0.5), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
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
                    fontWeight: isToday || isSelected || hasDoses
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasDoses
                    ? (isSelected ? Colors.white : primary)
                    : Colors.transparent,
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
  final Set<int> daysWithData;
  final bool isDark;
  final Color primary;
  final ValueChanged<DateTime> onDayTap;

  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.daysWithData,
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
          hasDoses: daysWithData.contains(d),
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
