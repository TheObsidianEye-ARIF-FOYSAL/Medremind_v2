import 'dart:math' as math;

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

// ── Time filter ───────────────────────────────────────────────────────────────

enum _TF { all, morning, afternoon, evening, night }

extension _TFX on _TF {
  String get label => ['All', 'Morning', 'Afternoon', 'Evening', 'Night'][index];
  String get emoji => ['✦', '🌅', '☀️', '🌆', '🌙'][index];
  String? get groupLabel =>
      index == 0 ? null : ['Morning', 'Afternoon', 'Evening', 'Night'][index - 1];
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  _TF _filter = _TF.all;
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
      body: resolvedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allGroups) {
          final filtered = _filter.groupLabel == null
              ? allGroups
              : allGroups
                  .where((g) => g.group.label == _filter.groupLabel)
                  .toList();

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fade,
                  child: _Header(stats: stats, primary: primary, isDark: isDark),
                ),
              ),

              // ── Filter tabs ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FilterTabs(
                  selected: _filter,
                  primary: primary,
                  isDark: isDark,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSizes.paddingMd)),

              // ── Dose cards or empty ──────────────────────────────────
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                    child: _Empty(primary: primary, filter: _filter))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.paddingMd),
                        child: _DoseCard(
                          resolved: filtered[i],
                          isDark: isDark,
                          primary: primary,
                          onTaken: () => _act(filtered[i], DoseStatus.taken),
                          onSkip: () => _act(filtered[i], DoseStatus.skipped),
                          onSnooze: () => _act(filtered[i], DoseStatus.snoozed),
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),

              // ── Mini calendar ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, 0,
                      AppSizes.paddingLg, 0),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: isDark ? DarkColors.surface : LightColors.surface,
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
      floatingActionButton: _GlowFAB(
        primary: primary,
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddMedicationScreen())),
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

// ── Gradient header ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DayStats stats;
  final Color primary;
  final bool isDark;
  const _Header(
      {required this.stats, required this.primary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: isDark ? 0.2 : 0.1),
            (isDark ? DarkColors.background : LightColors.background)
                .withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingLg,
        MediaQuery.of(context).padding.top + AppSizes.paddingMd,
        AppSizes.paddingLg,
        AppSizes.paddingLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_emoji(), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    _greet(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(
                  "Today's Pills",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (stats.total > 0) ...[
                  const SizedBox(height: AppSizes.paddingMd),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _Chip(label: '${stats.taken} taken', color: TagColors.taken),
                    _Chip(label: '${stats.pending} pending', color: primary),
                    if (stats.skipped > 0)
                      _Chip(
                          label: '${stats.skipped} skipped',
                          color: TagColors.skipped),
                  ]),
                ],
              ],
            ),
          ),
          if (stats.total > 0) ...[
            const SizedBox(width: AppSizes.paddingMd),
            _Ring(stats: stats, primary: primary),
          ],
        ],
      ),
    );
  }

  static String _emoji() {
    final h = DateTime.now().hour;
    if (h < 6) return '🌙';
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    return '🌆';
  }

  static String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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

// ── Adherence ring ────────────────────────────────────────────────────────────

class _Ring extends StatelessWidget {
  final DayStats stats;
  final Color primary;
  const _Ring({required this.stats, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              progress: stats.adherenceRate,
              color: primary,
              track: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${stats.taken}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: primary,
                    height: 1,
                  ),
                ),
                Text(
                  'of ${stats.total}',
                  style: const TextStyle(fontSize: 9, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  const _RingPainter(
      {required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 10) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    const start = -math.pi / 2;

    canvas.drawArc(
      rect, 0, 2 * math.pi, false,
      Paint()
        ..color = track
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect, start, 2 * math.pi * progress, false,
        Paint()
          ..color = color
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.progress != progress;
}

// ── Filter tabs ───────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final _TF selected;
  final Color primary;
  final bool isDark;
  final ValueChanged<_TF> onChanged;
  const _FilterTabs(
      {required this.selected,
      required this.primary,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
        children: _TF.values.map((f) {
          final sel = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? primary
                      : (isDark
                          ? DarkColors.surfaceVariant
                          : LightColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: primary.withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${f.emoji} ${f.label}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: sel ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Dose card ─────────────────────────────────────────────────────────────────

class _DoseCard extends StatelessWidget {
  final ResolvedDoseGroup resolved;
  final bool isDark;
  final Color primary;
  final VoidCallback onTaken, onSkip, onSnooze;

  const _DoseCard({
    required this.resolved,
    required this.isDark,
    required this.primary,
    required this.onTaken,
    required this.onSkip,
    required this.onSnooze,
  });

  static const _lc = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Evening': TagColors.evening,
    'Night': TagColors.night,
  };

  static const _fi = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = resolved.group;
    final lc = _lc[group.label] ?? primary;
    final taken = resolved.isTaken;
    final pending = resolved.isPending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: taken
            ? lc.withValues(alpha: isDark ? 0.12 : 0.07)
            : (isDark ? DarkColors.surface : LightColors.surface),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(
          left: BorderSide(
            color: taken ? lc.withValues(alpha: 0.5) : lc,
            width: 4,
          ),
        ),
        boxShadow: taken
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(group.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: lc, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(
                _fmt(group.timeOfDay),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!pending) ...[
                const SizedBox(width: 8),
                _Status(status: resolved.status),
              ],
            ]),
          ),

          Divider(
            height: 1,
            color:
                isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
          ),

          // Medicine rows
          ...resolved.items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: lc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                            color: lc.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Icon(_fi[item.form] ?? Icons.medication_rounded,
                        size: 20, color: lc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicineName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration:
                                taken ? TextDecoration.lineThrough : null,
                            decorationColor:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(children: [
                          Text(
                            '${_qty(item.quantity)} ${item.form.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (group.mealRelation != MealRelation.none) ...[
                            Text(' · ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                            Text(
                              _meal(group.mealRelation),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: lc.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ]),
              )),

          // Actions
          if (!taken) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 42,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [lc, lc.withValues(alpha: 0.75)]),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                        boxShadow: [
                          BoxShadow(
                              color: lc.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onTaken,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Taken'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Btn(
                    icon: Icons.snooze_rounded,
                    label: 'Snooze',
                    color: TagColors.snoozed,
                    onTap: onSnooze),
                const SizedBox(width: 8),
                _Btn(
                    icon: Icons.close_rounded,
                    label: 'Skip',
                    color: TagColors.missed,
                    onTap: onSkip),
              ]),
            ),
          ] else
            const SizedBox(height: 12),
        ],
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

  static String _meal(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => '🍽 Before meal',
        MealRelation.afterMeal => '🍽 After meal',
        _ => '',
      };

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final DoseStatus status;
  const _Status({required this.status});

  @override
  Widget build(BuildContext context) {
    final (c, ic) = switch (status) {
      DoseStatus.taken => (TagColors.taken, Icons.check_circle_rounded),
      DoseStatus.skipped => (TagColors.skipped, Icons.cancel_rounded),
      DoseStatus.missed => (TagColors.missed, Icons.error_rounded),
      DoseStatus.snoozed => (TagColors.snoozed, Icons.snooze_rounded),
      _ => (TagColors.pending, Icons.pending_rounded),
    };
    return Icon(ic, color: c, size: 20);
  }
}

class _Empty extends StatelessWidget {
  final Color primary;
  final _TF filter;
  const _Empty({required this.primary, required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFiltered = filter != _TF.all;
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
              isFiltered ? 'No ${filter.label} doses' : 'All clear! 🎉',
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

class _GlowFAB extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;
  const _GlowFAB({required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: [
              BoxShadow(
                  color: primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 22),
              SizedBox(width: 6),
              Text('Add Medicine',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ),
      );
}
