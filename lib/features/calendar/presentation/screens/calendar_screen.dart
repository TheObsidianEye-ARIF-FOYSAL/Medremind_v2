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

    final daysWithLogs = monthLogsAsync.when(
      data: (logs) => logs.map((l) => l.scheduledFor.day).toSet(),
      loading: () => <int>{},
      error: (_, __) => <int>{},
    );

    // Stats for selected date
    final selectedStats = selectedGroupsAsync.when(
      data: (groups) {
        final taken = groups.where((g) => g.status == DoseStatus.taken).length;
        final skipped = groups.where((g) => g.status == DoseStatus.skipped).length;
        final missed = groups.where((g) => g.status == DoseStatus.missed).length;
        final pending = groups.where((g) => g.status == DoseStatus.pending).length;
        return (total: groups.length, taken: taken, skipped: skipped, missed: missed, pending: pending);
      },
      loading: () => (total: 0, taken: 0, skipped: 0, missed: 0, pending: 0),
      error: (_, __) => (total: 0, taken: 0, skipped: 0, missed: 0, pending: 0),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingMd,
                  AppSizes.paddingLg, AppSizes.paddingMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Title + Month nav
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calendar',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            _monthLabel(calState.viewedMonth),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    _NavBtn(
                      icon: Icons.chevron_left_rounded,
                      onTap: notifier.prevMonth,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _NavBtn(
                      icon: Icons.chevron_right_rounded,
                      onTap: notifier.nextMonth,
                      isDark: isDark,
                    ),
                  ]),
                ],
              ),
            ),

            // ── Day-of-week headers ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
              child: Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),

            // ── Month grid ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
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

            // ── Selected date stats card ───────────────────────────────
            if (selectedStats.total > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLg),
                child: _StatsCard(
                  date: calState.selectedDate,
                  stats: selectedStats,
                  isDark: isDark,
                  primary: primary,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLg),
                child: _DateLabel(
                    date: calState.selectedDate, primary: primary),
              ),

            const SizedBox(height: AppSizes.paddingSm),

            Divider(
                height: 1,
                color: isDark
                    ? DarkColors.outlineVariant
                    : LightColors.outlineVariant),

            // ── Agenda for selected date ───────────────────────────────
            Expanded(
              child: selectedGroupsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (groups) => groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 52,
                              color: primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No doses scheduled',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add medicines and schedules to see them here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
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

// ── Navigation button ─────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _NavBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? DarkColors.surfaceVariant
                : LightColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(icon, size: 20),
        ),
      );
}

// ── Date label (fallback when no doses) ──────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final DateTime date;
  final Color primary;
  const _DateLabel({required this.date, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final label =
        isToday ? 'Today, ${_fmtDate(date)}' : _fmtDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXs),
      child: Text(label,
          style: theme.textTheme.labelLarge?.copyWith(
              color: isToday ? primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
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

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final DateTime date;
  final ({int total, int taken, int skipped, int missed, int pending}) stats;
  final bool isDark;
  final Color primary;

  const _StatsCard({
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
                _StatChip(count: stats.taken, label: 'Taken', color: TagColors.taken),
                const SizedBox(width: 6),
                if (stats.pending > 0)
                  _StatChip(count: stats.pending, label: 'Pending', color: TagColors.pending),
                if (stats.pending > 0) const SizedBox(width: 6),
                if (stats.missed > 0)
                  _StatChip(count: stats.missed, label: 'Missed', color: TagColors.missed),
                if (stats.missed > 0) const SizedBox(width: 6),
                if (stats.skipped > 0)
                  _StatChip(count: stats.skipped, label: 'Skipped', color: TagColors.skipped),
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

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(AppSizes.radiusPill),
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

    final firstDay = DateTime(month.year, month.month, 1);
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

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
          margin:
              const EdgeInsets.symmetric(horizontal: AppSizes.paddingSm),
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
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10),
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Status badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

