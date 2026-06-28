import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../medicine_cabinet/presentation/screens/add_medication_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groupsAsync = ref.watch(doseGroupsStreamProvider);
    final logsAsync = ref.watch(todayLogsStreamProvider);

    final greeting = _greeting();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
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
                          Text(greeting,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
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

            // ── Dose group list or empty state ──────────────────────────
            groupsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(primary: theme.colorScheme.primary),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, AppSizes.paddingLg,
                      AppSizes.paddingLg, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final group = groups[i];
                        return logsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (logs) {
                            final log = logs.where(
                                    (l) => l.doseGroupId == group.id)
                                .toList()
                                .firstOrNull;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSizes.paddingMd),
                              child: _DoseGroupCard(
                                group: group,
                                log: log,
                                isDark: isDark,
                                onTaken: () => _markStatus(
                                    context, ref, group, log,
                                    DoseStatus.taken),
                                onSkip: () => _markStatus(
                                    context, ref, group, log,
                                    DoseStatus.skipped),
                              ),
                            );
                          },
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Future<void> _markStatus(
    BuildContext context,
    WidgetRef ref,
    DoseGroup group,
    DoseLog? existingLog,
    DoseStatus status,
  ) async {
    final logRepo = ref.read(doseLogRepositoryProvider);
    if (existingLog == null) {
      final log = await logRepo.createPending(
        doseGroupId: group.id,
        scheduledFor: _todayAt(group.timeOfDay),
      );
      await logRepo.updateStatus(log.id, status);
    } else {
      await logRepo.updateStatus(existingLog.id, status);
    }
  }

  static DateTime _todayAt(String hhmm) {
    final now = DateTime.now();
    final parts = hhmm.split(':');
    return DateTime(
        now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning! ☀️';
    if (h < 17) return 'Good afternoon! 🌤️';
    return 'Good evening! 🌙';
  }
}

// ── Dose group card ───────────────────────────────────────────────────────────
class _DoseGroupCard extends StatelessWidget {
  final DoseGroup group;
  final DoseLog? log;
  final bool isDark;
  final VoidCallback onTaken;
  final VoidCallback onSkip;

  const _DoseGroupCard({
    required this.group,
    this.log,
    required this.isDark,
    required this.onTaken,
    required this.onSkip,
  });

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Night': TagColors.night,
    'Evening': TagColors.evening,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final labelColor = _labelColors[group.label] ?? primary;
    final status = log?.status ?? DoseStatus.pending;
    final isTaken = status == DoseStatus.taken;

    return Container(
      decoration: BoxDecoration(
        color: isTaken ? primary : (isDark ? DarkColors.surface : LightColors.surface),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        children: [
          // Time row
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
                    color: labelColor.withValues(alpha: isTaken ? 0.2 : 0.15),
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
                  _formatTime(group.timeOfDay),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isTaken
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Medicine info
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
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
                    Icons.medication_rounded,
                    size: 20,
                    color: isTaken ? Colors.white : primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${group.items.length} medicine${group.items.length != 1 ? 's' : ''}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isTaken ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 12,
                            color: isTaken
                                ? Colors.white70
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _mealText(group.mealRelation),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isTaken
                                  ? Colors.white70
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                _StatusBadge(status: status, isTaken: isTaken),
              ],
            ),
          ),

          // Action button
          if (!isTaken) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onTaken,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Taken'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  static String _mealText(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => 'Before Meals',
        MealRelation.afterMeal => 'After Meals',
        MealRelation.none => 'Anytime',
      };
}

class _StatusBadge extends StatelessWidget {
  final DoseStatus status;
  final bool isTaken;
  const _StatusBadge({required this.status, required this.isTaken});

  @override
  Widget build(BuildContext context) {
    if (status == DoseStatus.pending) return const SizedBox.shrink();
    final (color, icon, label) = switch (status) {
      DoseStatus.taken => (TagColors.taken, Icons.check_circle_rounded, 'Taken'),
      DoseStatus.skipped => (
          TagColors.skipped,
          Icons.cancel_rounded,
          'Skipped'
        ),
      DoseStatus.missed => (TagColors.missed, Icons.error_rounded, 'Missed'),
      DoseStatus.snoozed => (
          TagColors.snoozed,
          Icons.snooze_rounded,
          'Snoozed'
        ),
      _ => (TagColors.pending, Icons.pending_rounded, 'Pending'),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: isTaken ? Colors.white70 : color),
        const SizedBox(width: 4),
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

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color primary;
  const _EmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_liquid_rounded,
                size: 44, color: primary),
          ),
          const SizedBox(height: 24),
          Text('No medicines scheduled',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Medicine" to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

