import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_transitions.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../alternative_finder/presentation/screens/find_alternative_screen.dart';
import '../widgets/group_tile.dart';
import '../widgets/medicine_tile.dart';
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
                    onPressed: () => Navigator.of(context).push(
                      AppPageRoute(page: const FindAlternativeScreen()),
                    ),
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

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: TabBarView(
                  key: ValueKey(_tab.index),
                  controller: _tab,
                  children: const [
                    _MedicinesTab(),
                    _SchedulesTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _GradientFAB(
        onPressed: () async {
          if (_tab.index == 0) {
            await Navigator.of(context).push<void>(
              AppPageRoute(
                  page: const AddMedicationScreen(),
                  fullscreenDialog: true),
            );
          } else {
            await Navigator.of(context).push<bool>(
              AppPageRoute(
                  page: const AddDoseGroupScreen(),
                  fullscreenDialog: true),
            );
          }
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
          gradient:
              LinearGradient(colors: [primary, primary.withValues(alpha: 0.75)]),
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(label,
                  key: ValueKey(label),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Medicines Tab ─────────────────────────────────────────────────────────────

class _MedicinesTab extends ConsumerStatefulWidget {
  const _MedicinesTab();

  @override
  ConsumerState<_MedicinesTab> createState() => _MedicinesTabState();
}

class _MedicinesTabState extends ConsumerState<_MedicinesTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final medsAsync = ref.watch(medicinesStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, 0, AppSizes.paddingLg, AppSizes.paddingMd),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search medicines…',
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor:
                  isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: medsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allMeds) {
              final meds = _query.isEmpty
                  ? allMeds
                  : allMeds
                      .where((m) => m.brandName
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                      .toList();

              if (allMeds.isEmpty) {
                return _EmptyState(
                  icon: Icons.medication_rounded,
                  title: 'No medicines yet',
                  subtitle:
                      'Tap "+ Add Medicine" below to add your first medicine',
                  primary: primary,
                );
              }
              if (meds.isEmpty) {
                return Center(
                  child: Text(
                    'No results for "$_query"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg, 0, AppSizes.paddingLg, 150),
                itemCount: meds.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.paddingSm),
                itemBuilder: (ctx, i) => MedicineTile(med: meds[i]),
              );
            },
          ),
        ),
      ],
    );
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, 0, AppSizes.paddingLg, 150),
          itemCount: groups.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.paddingSm),
          itemBuilder: (ctx, i) => GroupTile(group: groups[i]),
        );
      },
    );
  }
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
              child: Icon(icon, size: 44, color: primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
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
