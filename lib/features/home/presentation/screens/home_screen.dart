import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/mini_calendar_strip.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/today_pills_provider.dart';
import '../widgets/dose_card.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/home_header.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  TimeFilter _filter = TimeFilter.all;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final resolvedAsync = ref.watch(resolvedDoseGroupsProvider);
    final stats = ref.watch(dayStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: resolvedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allGroups) {
            // Pending / snoozed → show in main list
            final pending = allGroups
                .where((g) =>
                    g.status == DoseStatus.pending ||
                    g.status == DoseStatus.snoozed)
                .where((g) =>
                    _filter.groupLabel == null ||
                    g.group.label == _filter.groupLabel)
                .toList();

            // Completed today (taken / skipped)
            final done = allGroups
                .where((g) =>
                    g.status == DoseStatus.taken ||
                    g.status == DoseStatus.skipped)
                .toList();

            return CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.paddingLg, AppSizes.paddingMd,
                          AppSizes.paddingLg, 0),
                      child: HomeHeader(
                          stats: stats, primary: primary, isDark: isDark),
                    ),
                  ),
                ),

                // ── Filter tabs ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: HomeFilterTabs(
                    selected: _filter,
                    primary: primary,
                    isDark: isDark,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSizes.paddingMd)),

                // ── Pending dose cards ───────────────────────────────────
                if (pending.isEmpty && done.isEmpty)
                  SliverToBoxAdapter(
                      child: _Empty(primary: primary, filter: _filter))
                else if (pending.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingLg),
                      child: Column(children: [
                        Icon(Icons.check_circle_rounded,
                            size: 52,
                            color: TagColors.taken.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text('All doses done for today!',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: TagColors.taken)),
                        const SizedBox(height: 4),
                        Text('Your tomorrow\'s doses are shown below.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                        const SizedBox(height: AppSizes.paddingLg),
                      ]),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingMd),
                          child: DoseCard(
                            resolved: pending[i],
                            isDark: isDark,
                            primary: primary,
                            onTaken: () =>
                                _act(pending[i], DoseStatus.taken),
                            onSkip: () =>
                                _act(pending[i], DoseStatus.skipped),
                            onSnooze: () =>
                                _act(pending[i], DoseStatus.snoozed),
                          ),
                        ),
                        childCount: pending.length,
                      ),
                    ),
                  ),

                // ── Done today section (collapsible) ─────────────────────
                if (done.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.paddingLg, 0,
                          AppSizes.paddingLg, AppSizes.paddingSm),
                      child: _SectionDivider(
                          label: 'Completed Today (${done.length})',
                          color: TagColors.taken),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingSm),
                          child: _CompletedCard(
                              resolved: done[i], isDark: isDark),
                        ),
                        childCount: done.length,
                      ),
                    ),
                  ),
                ],

                // ── Tomorrow section ──────────────────────────────────────
                if (done.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.paddingLg, AppSizes.paddingSm,
                          AppSizes.paddingLg, AppSizes.paddingSm),
                      child: _SectionDivider(
                          label: 'Tomorrow', color: primary),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingSm),
                          child: _TomorrowCard(
                              resolved: done[i],
                              isDark: isDark,
                              primary: primary),
                        ),
                        childCount: done.length,
                      ),
                    ),
                  ),
                ],

                // ── Mini calendar strip ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingLg, AppSizes.paddingMd,
                        AppSizes.paddingLg, 0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.surface
                            : LightColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(
                          color: isDark
                              ? DarkColors.outlineVariant
                              : LightColors.outlineVariant,
                        ),
                      ),
                      child: MiniCalendarStrip(
                        selectedDate: _selectedDay,
                        onDayTap: (d) => setState(() => _selectedDay = d),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _act(ResolvedDoseGroup r, DoseStatus status) async {
    final repo = ref.read(doseLogRepositoryProvider);
    final now = DateTime.now();
    final p = r.group.timeOfDay.split(':');
    final scheduled = DateTime(now.year, now.month, now.day,
        int.parse(p[0]), int.parse(p[1]));
    if (r.log == null) {
      final log = await repo.createPending(
          doseGroupId: r.group.id, scheduledFor: scheduled);
      await repo.updateStatus(log.id, status);
    } else {
      await repo.updateStatus(r.log!.id, status);
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final Color primary;
  final TimeFilter filter;
  const _Empty({required this.primary, required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFiltered = filter != TimeFilter.all;
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_list_off_rounded
                    : Icons.medication_liquid_rounded,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No ${filter.label} doses' : 'All clear!',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try selecting "All"'
                  : 'Tap + to add your first medicine',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionDivider({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: color.withValues(alpha: 0.2), height: 1)),
    ]);
  }
}

// ── Completed card (taken/skipped today) ──────────────────────────────────────

class _CompletedCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  final bool isDark;
  const _CompletedCard({required this.resolved, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = resolved.group;
    final isT = resolved.status == DoseStatus.taken;
    final color = isT ? TagColors.taken : TagColors.skipped;

    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.surface : LightColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(children: [
          Icon(
            isT ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${g.label} · ${_fmt(g.timeOfDay)} · '
              '${resolved.items.map((i) => i.medicineName).join(", ")}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(isT ? 'Done' : 'Skipped',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  static String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $per';
  }
}

// ── Tomorrow card ─────────────────────────────────────────────────────────────

class _TomorrowCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  final bool isDark;
  final Color primary;
  const _TomorrowCard(
      {required this.resolved, required this.isDark, required this.primary});

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Evening': TagColors.evening,
    'Night': TagColors.night,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = resolved.group;
    final color = _labelColors[g.label] ?? primary;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? DarkColors.surface : LightColors.surface)
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border(left: BorderSide(color: color.withValues(alpha: 0.5), width: 3)),
      ),
      child: Row(children: [
        Icon(Icons.schedule_rounded, color: color.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${g.label} · ${_fmt(g.timeOfDay)} · '
            '${resolved.items.map((i) => i.medicineName).join(", ")}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Text('Tomorrow',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: primary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  static String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $per';
  }
}
