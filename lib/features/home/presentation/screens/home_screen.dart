import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/mini_calendar_strip.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../medicine_cabinet/presentation/screens/add_medication_screen.dart';
import '../providers/today_pills_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedAsync = ref.watch(resolvedDoseGroupsProvider);
    final stats = ref.watch(dayStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg, AppSizes.paddingLg,
                    AppSizes.paddingLg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text("Today's Pills",
                              style: theme.textTheme.headlineMedium),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.filter_list_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? DarkColors.surfaceVariant
                            : LightColors.surfaceVariant,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Day stats strip ──────────────────────────────────────────
            if (stats.total > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, AppSizes.paddingMd,
                      AppSizes.paddingLg, 0),
                  child: _StatsRow(stats: stats),
                ),
              ),

            // ── Dose cards ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingLg,
                  AppSizes.paddingLg, 0),
              sliver: resolvedAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $e'))),
                data: (groups) {
                  if (groups.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                          primary: theme.colorScheme.primary),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.paddingMd),
                        child: _DoseGroupCard(
                          resolved: groups[i],
                          isDark: isDark,
                          onTaken: () =>
                              _act(groups[i], DoseStatus.taken),
                          onSkip: () =>
                              _act(groups[i], DoseStatus.skipped),
                          onSnooze: () =>
                              _act(groups[i], DoseStatus.snoozed),
                        ),
                      ),
                      childCount: groups.length,
                    ),
                  );
                },
              ),
            ),

            // ── Mini calendar strip ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg, AppSizes.paddingMd,
                    AppSizes.paddingLg, 0),
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color:
                      isDark ? DarkColors.surface : LightColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusCard),
                ),
                child: MiniCalendarStrip(
                  selectedDate: _selectedDay,
                  onDayTap: (d) => setState(() => _selectedDay = d),
                ),
              ),
            ),

            // Bottom padding for floating nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const AddMedicationScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Future<void> _act(ResolvedDoseGroup resolved, DoseStatus status) async {
    final logRepo = ref.read(doseLogRepositoryProvider);
    if (resolved.log == null) {
      final log = await logRepo.createPending(
        doseGroupId: resolved.group.id,
        scheduledFor: _todayAt(resolved.group.timeOfDay),
      );
      await logRepo.updateStatus(log.id, status);
    } else {
      await logRepo.updateStatus(resolved.log!.id, status);
    }
  }

  static DateTime _todayAt(String hhmm) {
    final n = DateTime.now();
    final p = hhmm.split(':');
    return DateTime(n.year, n.month, n.day, int.parse(p[0]), int.parse(p[1]));
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning! ☀️';
    if (h < 17) return 'Good afternoon! 🌤️';
    return 'Good evening! 🌙';
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final DayStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _StatChip(
          label: '${stats.taken} Taken',
          color: TagColors.taken,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: '${stats.pending} Pending',
          color: TagColors.pending,
          isDark: isDark,
        ),
        if (stats.skipped > 0) ...[
          const SizedBox(width: 8),
          _StatChip(
            label: '${stats.skipped} Skipped',
            color: TagColors.skipped,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _StatChip(
      {required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
}

// ── Dose group card ───────────────────────────────────────────────────────────
class _DoseGroupCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  final bool isDark;
  final VoidCallback onTaken;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  const _DoseGroupCard({
    required this.resolved,
    required this.isDark,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
  });

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Night': TagColors.night,
    'Evening': TagColors.evening,
  };

  static const _formIcons = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final group = resolved.group;
    final isTaken = resolved.isTaken;
    final labelColor =
        _labelColors[group.label] ?? primary;

    final cardBg = isTaken
        ? primary
        : (isDark ? DarkColors.surface : LightColors.surface);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMd, 10, AppSizes.paddingMd, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: labelColor
                        .withValues(alpha: isTaken ? 0.2 : 0.14),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    group.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isTaken ? Colors.white70 : labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _fmt(group.timeOfDay),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isTaken
                        ? Colors.white60
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── Medicine items ───────────────────────────────────────────
          ...resolved.items.map(
            (item) => Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd, AppSizes.paddingSm,
                  AppSizes.paddingMd, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isTaken
                          ? Colors.white.withValues(alpha: 0.2)
                          : primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      _formIcons[item.form] ??
                          Icons.medication_rounded,
                      size: 18,
                      color: isTaken ? Colors.white : primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicineName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isTaken ? Colors.white : null,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${_qty(item.quantity)} ${item.form.name}',
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                color: isTaken
                                    ? Colors.white70
                                    : theme
                                        .colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (group.mealRelation !=
                                MealRelation.none) ...[
                              Text(
                                ' · ',
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: isTaken
                                      ? Colors.white54
                                      : theme.colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                              Icon(
                                Icons.restaurant_rounded,
                                size: 10,
                                color: isTaken
                                    ? Colors.white70
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _mealText(group.mealRelation),
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: isTaken
                                      ? Colors.white70
                                      : theme.colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  if (!resolved.isPending)
                    _StatusBadge(
                        status: resolved.status, isTaken: isTaken),
                ],
              ),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────
          if (!isTaken) ...[
            const SizedBox(height: AppSizes.paddingSm),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onTaken,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Taken'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onSnooze,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              theme.colorScheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill),
                          ),
                        ),
                        child: const Text('Snooze'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TagColors.missed,
                          side: BorderSide(
                              color: TagColors.missed
                                  .withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill),
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: AppSizes.paddingMd),
        ],
      ),
    );
  }

  String _fmt(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  String _mealText(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => 'Before',
        MealRelation.afterMeal => 'After',
        _ => '',
      };

  String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}

class _StatusBadge extends StatelessWidget {
  final DoseStatus status;
  final bool isTaken;
  const _StatusBadge({required this.status, required this.isTaken});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      DoseStatus.taken =>
        (TagColors.taken, Icons.check_circle_rounded, 'Taken'),
      DoseStatus.skipped =>
        (TagColors.skipped, Icons.cancel_rounded, 'Skipped'),
      DoseStatus.missed =>
        (TagColors.missed, Icons.error_rounded, 'Missed'),
      DoseStatus.snoozed =>
        (TagColors.snoozed, Icons.snooze_rounded, 'Snoozed'),
      _ => (TagColors.pending, Icons.pending_rounded, ''),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: isTaken ? Colors.white70 : color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isTaken ? Colors.white70 : color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primary;
  const _EmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_liquid_rounded,
                  size: 38, color: primary),
            ),
            const SizedBox(height: 16),
            Text('No medicines scheduled',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add Medicine" to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
