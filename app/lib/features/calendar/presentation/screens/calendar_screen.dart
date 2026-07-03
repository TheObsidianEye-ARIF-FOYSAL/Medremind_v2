import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_log.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/calendar_provider.dart';
import '../widgets/agenda_card.dart';
import '../widgets/month_grid.dart';
import '../widgets/stats_card.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _monthYearLabel(DateTime d) => '${_months[d.month]} ${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    final calState = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    final dayStatusAsync = ref.watch(monthDayStatusProvider(calState.viewedMonth));
    final monthAdherenceAsync = ref.watch(monthAdherenceProvider(calState.viewedMonth));
    final selectedGroupsAsync = ref.watch(selectedDateGroupsProvider(calState.selectedDate));

    final now = DateTime.now();
    final isViewingCurrentMonth = calState.viewedMonth.year == now.year &&
        calState.viewedMonth.month == now.month;

    // Build day status map (empty while loading)
    final dayStatuses = dayStatusAsync.when(
      data: (m) => m,
      loading: () => <int, CalendarDayStatus>{},
      error: (_, __) => <int, CalendarDayStatus>{},
    );

    // Stats for selected date
    final selectedStats = selectedGroupsAsync.when(
      data: (groups) {
        final taken = groups.where((g) => g.status == DoseStatus.taken).length;
        final skipped = groups.where((g) => g.status == DoseStatus.skipped).length;
        final missed = groups.where((g) => g.status == DoseStatus.missed).length;
        final pending = groups.where((g) => g.status == DoseStatus.pending).length;
        return (
          total: groups.length,
          taken: taken,
          skipped: skipped,
          missed: missed,
          pending: pending
        );
      },
      loading: () => (total: 0, taken: 0, skipped: 0, missed: 0, pending: 0),
      error: (_, __) => (total: 0, taken: 0, skipped: 0, missed: 0, pending: 0),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: selectedGroupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (groups) => CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
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
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Planner',
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          // Month adherence summary
                          monthAdherenceAsync.when(
                            data: (s) => s.total > 0
                                ? Text(
                                    '${s.taken}/${s.total} doses taken this month',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: muted),
                                  )
                                : Text('Tap any day to see its schedule',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: muted)),
                            loading: () => Text('Tap any day to see its schedule',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: muted)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    // Today button (only visible when not on current month)
                    if (!isViewingCurrentMonth)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: notifier.goToToday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusPill),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.today_rounded, size: 14, color: primary),
                              const SizedBox(width: 4),
                              Text('Today',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                    _NavBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: notifier.prevMonth,
                        isDark: isDark),
                    const SizedBox(width: 4),
                    _NavBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: notifier.nextMonth,
                        isDark: isDark),
                  ]),
                ),
              ),

              // ── Month / year label ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, 0, AppSizes.paddingLg,
                      AppSizes.paddingSm),
                  child: Row(children: [
                    Text(
                      _monthYearLabel(calState.viewedMonth),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, color: primary),
                    ),
                    if (isViewingCurrentMonth) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text('Current',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ),
              ),

              // ── Day-of-week header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLg),
                  child: Row(
                    children:
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(d,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),

              // ── Month grid ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd),
                  child: CalendarMonthGrid(
                    month: calState.viewedMonth,
                    selectedDate: calState.selectedDate,
                    dayStatuses: dayStatuses,
                    isDark: isDark,
                    primary: primary,
                    onDayTap: notifier.selectDate,
                  ),
                ),
              ),

              // ── Dot legend ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, AppSizes.paddingSm,
                      AppSizes.paddingLg, AppSizes.paddingSm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: TagColors.taken, label: 'All taken'),
                      const SizedBox(width: 14),
                      _LegendDot(color: TagColors.snoozed, label: 'Partial'),
                      const SizedBox(width: 14),
                      _LegendDot(color: TagColors.missed, label: 'Missed'),
                      const SizedBox(width: 14),
                      _LegendDot(
                          color: primary.withValues(alpha: 0.6),
                          label: 'Scheduled'),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSizes.paddingMd)),

              // ── Selected-day stats card ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLg),
                  child: selectedStats.total > 0
                      ? CalendarStatsCard(
                          date: calState.selectedDate,
                          stats: selectedStats,
                          isDark: isDark,
                          primary: primary,
                        )
                      : _DateLabel(
                          date: calState.selectedDate, primary: primary),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.paddingSm),
                  child: Divider(
                      height: 1,
                      color: isDark
                          ? DarkColors.outlineVariant
                          : LightColors.outlineVariant),
                ),
              ),

              // ── Agenda items ──────────────────────────────────────────────
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingXl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded,
                              size: 52,
                              color: primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No doses scheduled',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            'Add medicines and schedules to see them here',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.paddingLg,
                      AppSizes.paddingMd, AppSizes.paddingLg, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.paddingSm),
                        child: CalendarAgendaCard(resolved: groups[i]),
                      ),
                      childCount: groups.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
    ]);
  }
}

// ── Date label (when no doses) ────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final DateTime date;
  final Color primary;
  const _DateLabel({required this.date, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final label = isToday ? 'Today, ${_fmtDate(date)}' : _fmtDate(date);
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
