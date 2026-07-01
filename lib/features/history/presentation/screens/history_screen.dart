import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/history_provider.dart';
import '../widgets/adherence_heatmap.dart';
import '../widgets/log_entry_widget.dart';
import '../widgets/week_summary_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final histState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final logsAsync = ref.watch(historyLogsProvider(histState.viewedMonth));
    final groupsAsync = ref.watch(doseGroupsStreamProvider);

    final groupLabels = groupsAsync.when(
      data: (groups) => {for (final g in groups) g.id: g.label},
      loading: () => <String, String>{},
      error: (_, __) => <String, String>{},
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (logs) {
            final adherence = ref.read(historyAdherenceProvider(logs));
            final week = computeWeekSummary(logs);

            final displayedLogs = _selectedDay == null
                ? logs
                : logs.where((l) {
                    final d = l.scheduledFor;
                    return d.day == _selectedDay &&
                        d.month == histState.viewedMonth.month &&
                        d.year == histState.viewedMonth.year;
                  }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingLg,
                        AppSizes.paddingLg, 0),
                    child: Text('History',
                        style: theme.textTheme.headlineMedium),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: WeekSummaryCard(
                      summary: week,
                      isDark: isDark,
                      primary: primary,
                    ),
                  ),
                ),

                // ── Month navigation ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Adherence heatmap',
                            style: theme.textTheme.titleSmall),
                        Row(children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () {
                              notifier.prevMonth();
                              setState(() => _selectedDay = null);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            _monthLabel(histState.viewedMonth),
                            style: theme.textTheme.labelLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () {
                              notifier.nextMonth();
                              setState(() => _selectedDay = null);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingSm,
                        AppSizes.paddingLg, 0),
                    child: AdherenceHeatmap(
                      month: histState.viewedMonth,
                      adherence: adherence,
                      isDark: isDark,
                      primary: primary,
                      selectedDay: _selectedDay,
                      onDayTap: (day) => setState(() {
                        _selectedDay = _selectedDay == day ? null : day;
                      }),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: HeatmapLegend(primary: primary),
                  ),
                ),

                // ── Dose log header ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingLg,
                        AppSizes.paddingLg, AppSizes.paddingSm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dose log', style: theme.textTheme.titleSmall),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _selectedDay != null
                              ? TextButton.icon(
                                  key: const ValueKey('filter'),
                                  onPressed: () =>
                                      setState(() => _selectedDay = null),
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  label: Text(
                                    'Day $_selectedDay only',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Log entries ─────────────────────────────────────
                if (displayedLogs.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, 0, AppSizes.paddingLg, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final log = displayedLogs.reversed.toList()[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSizes.paddingSm),
                            child: LogEntryWidget(
                              log: log,
                              isDark: isDark,
                              primary: primary,
                              groupLabels: groupLabels,
                            ),
                          );
                        },
                        childCount: displayedLogs.length,
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 110),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.history_rounded,
                              size: 56,
                              color: primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDay != null
                                ? 'No logs for day $_selectedDay'
                                : 'No logs for this month',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
