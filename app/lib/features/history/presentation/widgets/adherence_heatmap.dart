import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/history_provider.dart';

class AdherenceHeatmap extends StatelessWidget {
  final DateTime month;
  final List<DayAdherence> adherence;
  final bool isDark;
  final Color primary;
  final int? selectedDay;
  final ValueChanged<int> onDayTap;

  const AdherenceHeatmap({
    super.key,
    required this.month,
    required this.adherence,
    required this.isDark,
    required this.primary,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adMap = {for (final a in adherence) a.date.day: a};

    final firstDay = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              HeatCell(
                day: d,
                adhere: adMap[d],
                isDark: isDark,
                primary: primary,
                month: month,
                isSelected: selectedDay == d,
                onTap: () => onDayTap(d),
              ),
          ],
        ),
      ],
    );
  }
}

class HeatCell extends StatelessWidget {
  final int day;
  final DayAdherence? adhere;
  final bool isDark;
  final Color primary;
  final DateTime month;
  final bool isSelected;
  final VoidCallback onTap;

  const HeatCell({
    super.key,
    required this.day,
    required this.adhere,
    required this.isDark,
    required this.primary,
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  Color _cellColor() {
    if (adhere == null) {
      return isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant;
    }
    if (adhere!.rate >= 1.0) return TagColors.taken;
    if (adhere!.rate > 0.5) return TagColors.taken.withValues(alpha: 0.5);
    if (adhere!.rate > 0) return TagColors.missed.withValues(alpha: 0.5);
    return TagColors.missed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = today.day == day &&
        today.month == month.month &&
        today.year == month.year;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _cellColor(),
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: primary, width: 2.5)
              : isToday
                  ? Border.all(color: primary, width: 1.5)
                  : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: adhere != null
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class HeatmapLegend extends StatelessWidget {
  final Color primary;
  const HeatmapLegend({super.key, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(spacing: 12, runSpacing: 6, children: [
      _LegendItem(
        color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
        label: 'No data',
        theme: theme,
      ),
      _LegendItem(color: TagColors.taken, label: 'All taken', theme: theme),
      _LegendItem(
          color: TagColors.taken.withValues(alpha: 0.5),
          label: 'Partial',
          theme: theme),
      _LegendItem(color: TagColors.missed, label: 'Missed', theme: theme),
    ]);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final ThemeData theme;
  const _LegendItem(
      {required this.color, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      );
}
