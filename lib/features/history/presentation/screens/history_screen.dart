import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_log.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final histState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final logsAsync =
        ref.watch(historyLogsProvider(histState.viewedMonth));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: logsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (logs) {
            final adherence =
                ref.read(historyAdherenceProvider(logs));
            final week = computeWeekSummary(logs);

            return CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingLg,
                        AppSizes.paddingLg, 0),
                    child: Text('History',
                        style: theme.textTheme.headlineMedium),
                  ),
                ),

                // ── This week summary ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: _WeekSummaryCard(
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Adherence heatmap',
                            style: theme.textTheme.titleSmall),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.chevron_left_rounded),
                              onPressed: notifier.prevMonth,
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              _monthLabel(histState.viewedMonth),
                              style: theme.textTheme.labelLarge,
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.chevron_right_rounded),
                              onPressed: notifier.nextMonth,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Heatmap ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingSm,
                        AppSizes.paddingLg, 0),
                    child: _AdherenceHeatmap(
                      month: histState.viewedMonth,
                      adherence: adherence,
                      isDark: isDark,
                      primary: primary,
                    ),
                  ),
                ),

                // ── Legend ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: _HeatmapLegend(primary: primary),
                  ),
                ),

                // ── Recent logs list ────────────────────────────────
                if (logs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.paddingLg, AppSizes.paddingLg,
                          AppSizes.paddingLg, AppSizes.paddingSm),
                      child: Text('Dose log',
                          style: theme.textTheme.titleSmall),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, 0,
                        AppSizes.paddingLg, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final log = logs.reversed.toList()[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSizes.paddingSm),
                            child: _LogEntry(
                                log: log,
                                isDark: isDark,
                                primary: primary),
                          );
                        },
                        childCount: logs.length,
                      ),
                    ),
                  ),
                ] else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded,
                                size: 56,
                                color:
                                    primary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'No logs for this month',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: theme.colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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

// ── Week summary card ─────────────────────────────────────────────────────────

class _WeekSummaryCard extends StatelessWidget {
  final WeekSummary summary;
  final bool isDark;
  final Color primary;

  const _WeekSummaryCard(
      {required this.summary,
      required this.isDark,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (summary.rate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.2),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 4),
                Text(
                  '$pct% adherence',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: primary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(
                        label: '${summary.taken} Taken',
                        color: TagColors.taken),
                    _Pill(
                        label: '${summary.missed} Missed',
                        color: TagColors.missed),
                    _Pill(
                        label: '${summary.skipped} Skipped',
                        color: TagColors.skipped),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: summary.rate,
                  strokeWidth: 6,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  color: primary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$pct%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}

// ── Adherence heatmap ─────────────────────────────────────────────────────────

class _AdherenceHeatmap extends StatelessWidget {
  final DateTime month;
  final List<DayAdherence> adherence;
  final bool isDark;
  final Color primary;

  const _AdherenceHeatmap({
    required this.month,
    required this.adherence,
    required this.isDark,
    required this.primary,
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
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ),
                ),
              )
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
            for (var i = 0; i < leadingBlanks; i++)
              const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              _HeatCell(
                day: d,
                adhere: adMap[d],
                isDark: isDark,
                primary: primary,
                theme: theme,
                month: month,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  final int day;
  final DayAdherence? adhere;
  final bool isDark;
  final Color primary;
  final ThemeData theme;
  final DateTime month;

  const _HeatCell({
    required this.day,
    required this.adhere,
    required this.isDark,
    required this.primary,
    required this.theme,
    required this.month,
  });

  Color _cellColor() {
    if (adhere == null) {
      return isDark
          ? DarkColors.surfaceVariant
          : LightColors.surfaceVariant;
    }
    if (adhere!.rate >= 1.0) return TagColors.taken;
    if (adhere!.rate > 0.5) {
      return TagColors.taken.withValues(alpha: 0.5);
    }
    if (adhere!.rate > 0) return TagColors.missed.withValues(alpha: 0.5);
    return TagColors.missed;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = today.day == day &&
        today.month == month.month &&
        today.year == month.year;

    return Container(
      decoration: BoxDecoration(
        color: _cellColor(),
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: primary, width: 1.5)
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
          ),
        ),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final Color primary;
  const _HeatmapLegend({required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: isDark
              ? DarkColors.surfaceVariant
              : LightColors.surfaceVariant,
          label: 'No data',
          theme: theme,
        ),
        _LegendItem(
            color: TagColors.taken, label: 'All taken', theme: theme),
        _LegendItem(
            color: TagColors.taken.withValues(alpha: 0.5),
            label: 'Partial',
            theme: theme),
        _LegendItem(
            color: TagColors.missed, label: 'Missed', theme: theme),
      ],
    );
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

// ── Log entry ─────────────────────────────────────────────────────────────────

class _LogEntry extends StatelessWidget {
  final DoseLog log;
  final bool isDark;
  final Color primary;

  const _LogEntry(
      {required this.log,
      required this.isDark,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, icon, label) = switch (log.status) {
      DoseStatus.taken =>
        (TagColors.taken, Icons.check_circle_rounded, 'Taken'),
      DoseStatus.skipped =>
        (TagColors.skipped, Icons.cancel_outlined, 'Skipped'),
      DoseStatus.missed =>
        (TagColors.missed, Icons.error_outline_rounded, 'Missed'),
      DoseStatus.snoozed =>
        (TagColors.snoozed, Icons.snooze_rounded, 'Snoozed'),
      _ =>
        (TagColors.pending, Icons.radio_button_unchecked, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.doseGroupId,
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _fmt(log.scheduledFor),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day} · ${dh.toString().padLeft(2, '0')}:$m $period';
  }
}
