import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import 'add_dose_group_screen.dart';
import 'add_medication_screen.dart';

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});

  @override
  ConsumerState<MedicineListScreen> createState() =>
      _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingLg,
                  AppSizes.paddingMd, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Medicine Cabinet',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800)),
                        Text(
                          'Manage medicines & schedules',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Finder shortcut
                  IconButton(
                    tooltip: 'Find Alternatives',
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(Icons.compare_arrows_rounded,
                          color: primary, size: 20),
                    ),
                    onPressed: () => context.go(AppRoutes.finder),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingMd,
                  AppSizes.paddingLg, 0),
              child: _SegmentedTabs(
                controller: _tab,
                isDark: isDark,
                primary: primary,
              ),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            // ── Tab views ─────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _MedicinesTab(),
                  _SchedulesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // FAB changes based on current tab
      floatingActionButton: _GradientFAB(
        onPressed: () async {
          if (_tab.index == 0) {
            // Add individual medicine
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const AddMedicationScreen()),
            );
          } else {
            // Add dose group
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const AddDoseGroupScreen()),
            );
          }
          // Rebuild to refresh lists
          if (mounted) setState(() {});
        },
        label: _tab.index == 0 ? 'Add Medicine' : 'New Group',
        icon: Icons.add_rounded,
        primary: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ── Segmented tabs ────────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final Color primary;

  const _SegmentedTabs({
    required this.controller,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: theme.textTheme.labelMedium,
        tabs: const [
          Tab(text: 'Medicines'),
          Tab(text: 'Schedules'),
        ],
      ),
    );
  }
}

// ── Gradient FAB ──────────────────────────────────────────────────────────────

class _GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color primary;

  const _GradientFAB({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 88),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.75)]),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Medicines Tab ─────────────────────────────────────────────────────────────

class _MedicinesTab extends ConsumerWidget {
  const _MedicinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final medsAsync = ref.watch(medicinesStreamProvider);

    return medsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (meds) {
        if (meds.isEmpty) {
          return _EmptyState(
            icon: Icons.medication_rounded,
            title: 'No medicines yet',
            subtitle: 'Tap "+ Add Medicine" below to add your first medicine',
            primary: theme.colorScheme.primary,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, 0, AppSizes.paddingLg, 150),
          itemCount: meds.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.paddingSm),
          itemBuilder: (ctx, i) => _MedicineTile(med: meds[i]),
        );
      },
    );
  }
}

class _MedicineTile extends ConsumerWidget {
  final Medicine med;
  const _MedicineTile({required this.med});

  static const _formIcons = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  static const _formColors = {
    MedicineForm.tablet: Color(0xFF6C5CE7),
    MedicineForm.pill: Color(0xFF00B4D8),
    MedicineForm.syrup: Color(0xFF00C896),
    MedicineForm.syringe: Color(0xFFFF7675),
    MedicineForm.other: Color(0xFFA0A0A0),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = _formColors[med.form] ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              _formIcons[med.form] ?? Icons.medication_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.brandName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (med.strength.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    med.strength,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              med.form.name[0].toUpperCase() + med.form.name.substring(1),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: iconColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded, size: 18,
                        color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Remove'),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Medicine'),
          content: Text('Remove "${med.brandName}" from your cabinet?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove',
                    style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(medicineRepositoryProvider).delete(med.id);
      }
    }
  }
}

// ── Schedules Tab ─────────────────────────────────────────────────────────────

class _SchedulesTab extends ConsumerWidget {
  const _SchedulesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(doseGroupsStreamProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (groups) {
        if (groups.isEmpty) {
          return _EmptyState(
            icon: Icons.schedule_rounded,
            title: 'No schedules yet',
            subtitle: 'Tap "+ New Group" below to create a dose schedule',
            primary: theme.colorScheme.primary,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, 0, AppSizes.paddingLg, 150),
          itemCount: groups.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.paddingSm),
          itemBuilder: (ctx, i) => _GroupTile(group: groups[i]),
        );
      },
    );
  }
}

class _GroupTile extends ConsumerWidget {
  final DoseGroup group;
  const _GroupTile({required this.group});

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Evening': TagColors.evening,
    'Night': TagColors.night,
  };

  static const _labelIcons = {
    'Morning': Icons.wb_sunny_rounded,
    'Afternoon': Icons.wb_cloudy_rounded,
    'Evening': Icons.nights_stay_outlined,
    'Night': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _labelColors[group.label] ?? theme.colorScheme.primary;
    final icon = _labelIcons[group.label] ?? Icons.schedule_rounded;

    final timeStr = _fmtTime(group.timeOfDay);
    final medCount = group.items.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(group.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (!group.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Text('Paused',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                '$timeStr · $medCount ${medCount == 1 ? 'medicine' : 'medicines'}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              if (group.mealRelation != MealRelation.none)
                Text(
                  group.mealRelation == MealRelation.beforeMeal
                      ? '· Before meal'
                      : '· After meal',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        // Medicine pill chips
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final item in group.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    _qty(item.quantity),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (group.items.length > 2)
              Text('+${group.items.length - 2} more',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          onSelected: (v) => _onMenu(context, ref, v),
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    group.isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(group.isActive ? 'Pause' : 'Resume'),
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18,
                      color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Remove'),
                ])),
          ],
        ),
      ]),
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(doseGroupRepositoryProvider);
    if (action == 'toggle') {
      await repo.setActive(group.id, active: !group.isActive);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Dose Group'),
          content: Text(
              'Remove "${group.label}" dose group? This will also delete all logs for this group.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove',
                    style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.delete(group.id);
      }
    }
  }

  static String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $per';
  }

  static String _qty(double q) =>
      q == q.truncateToDouble() ? '×${q.toInt()}' : '×$q';
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 44, color: primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
