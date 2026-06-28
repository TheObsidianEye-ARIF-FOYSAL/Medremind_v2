import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../home/presentation/providers/today_pills_provider.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final calState = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    final monthLogsAsync =
        ref.watch(monthLogsProvider(calState.viewedMonth));
    final selectedGroupsAsync =
        ref.watch(selectedDateGroupsProvider(calState.selectedDate));

    // Build a set of days that have dose logs this month
    final daysWithLogs = monthLogsAsync.when(
      data: (logs) =>
          logs.map((l) => l.scheduledFor.day).toSet(),
      loading: () => <int>{},
      error: (_, __) => <int>{},
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingLg,
                  AppSizes.paddingLg, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calendar',
                      style: theme.textTheme.headlineMedium),
                  Icon(Icons.notifications_none_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),

            // ── Month header + navigation ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingMd,
                  AppSizes.paddingLg, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: notifier.prevMonth,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    _monthLabel(calState.viewedMonth),
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: notifier.nextMonth,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ── Day-of-week headers ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg, vertical: 8),
              child: Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // ── Month grid ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd),
              child: _MonthGrid(
                month: calState.viewedMonth,
                selectedDate: calState.selectedDate,
                daysWithData: daysWithLogs,
                isDark: isDark,
                primary: primary,
                onDayTap: notifier.selectDate,
              ),
            ),

            const SizedBox(height: AppSizes.paddingMd),
            Divider(
                height: 1,
                color: isDark
                    ? DarkColors.outlineVariant
                    : LightColors.outlineVariant),

            // ── Agenda for selected date ───────────────────────────────
            Expanded(
              child: selectedGroupsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error: $e')),
                data: (groups) => groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 48,
                              color: primary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No doses scheduled',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: theme.colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.paddingLg,
                            AppSizes.paddingMd,
                            AppSizes.paddingLg, 110),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSizes.paddingSm),
                        itemBuilder: (ctx, i) =>
                            _AgendaCard(resolved: groups[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ── Month grid ────────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Set<int> daysWithData;
  final bool isDark;
  final Color primary;
  final ValueChanged<DateTime> onDayTap;

  const _MonthGrid({
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

    // weekday: Mon=1 … Sun=7; we use Mon-based grid
    final firstDay = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
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
          onTap: () =>
              onDayTap(DateTime(month.year, month.month, d)),
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

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasDoses;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final ThemeData theme;

  const _DayCell({
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
                // Show outline for days with dose data (not today/selected)
                border: hasDoses && !isSelected && !isToday
                    ? Border.all(
                        color: primary.withValues(alpha: 0.5),
                        width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight:
                        isToday || isSelected || hasDoses
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
                    ? (isSelected
                        ? Colors.white
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

// ── Agenda card ───────────────────────────────────────────────────────────────

class _AgendaCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  const _AgendaCard({required this.resolved});

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Night': TagColors.night,
    'Evening': TagColors.evening,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final group = resolved.group;
    final labelColor = _labelColors[group.label] ?? primary;

    final (statusColor, statusLabel) = switch (resolved.status) {
      DoseStatus.taken => (TagColors.taken, 'Taken ✓'),
      DoseStatus.skipped => (TagColors.skipped, 'Skipped'),
      DoseStatus.missed => (TagColors.missed, 'Missed'),
      DoseStatus.snoozed => (TagColors.snoozed, 'Snoozed'),
      _ => (TagColors.pending, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmt(group.timeOfDay),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: primary),
                ),
              ],
            ),
          ),

          // Vertical divider
          Container(
            width: 2,
            height: 48,
            margin:
                const EdgeInsets.symmetric(horizontal: AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // Medicine info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: labelColor),
                ),
                const SizedBox(height: 2),
                Text(
                  resolved.items.map((i) => i.medicineName).join(', '),
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  resolved.items
                      .map((i) =>
                          '${_qty(i.quantity)} ${i.form.name}')
                      .join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
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
