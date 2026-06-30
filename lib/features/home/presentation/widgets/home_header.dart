import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/today_pills_provider.dart';

// ── Header chip ────────────────────────────────────────────────────────────────

class HomeChip extends StatelessWidget {
  final String label;
  final Color color;
  const HomeChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ── Adherence ring painter ─────────────────────────────────────────────────────

class AdherenceRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  const AdherenceRingPainter(
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
  bool shouldRepaint(covariant AdherenceRingPainter o) => o.progress != progress;
}

// ── Adherence ring ─────────────────────────────────────────────────────────────

class AdherenceRing extends StatelessWidget {
  final DayStats stats;
  final Color primary;
  const AdherenceRing({super.key, required this.stats, required this.primary});

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
            painter: AdherenceRingPainter(
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

// ── Home header ────────────────────────────────────────────────────────────────

class HomeHeader extends ConsumerWidget {
  final DayStats stats;
  final Color primary;
  final bool isDark;
  const HomeHeader({
    super.key,
    required this.stats,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final userName = ref.watch(userNameProvider);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final pct = stats.total > 0
        ? (stats.taken / stats.total).clamp(0.0, 1.0)
        : 0.0;
    final motiveLine = _motiveLine(pct, stats);

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.paddingLg, 0, AppSizes.paddingLg, 0),
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        MediaQuery.of(context).padding.top + AppSizes.paddingMd,
        AppSizes.paddingMd,
        AppSizes.paddingLg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: isDark ? 0.25 : 0.14),
            primary.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: greeting + ring ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        _greet(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 4),
                    Text(
                      userName.isNotEmpty ? userName : "Today's Pills",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} · ${now.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              AdherenceRing(stats: stats, primary: primary),
            ],
          ),

          if (stats.total > 0) ...[
            const SizedBox(height: AppSizes.paddingMd),

            // ── Progress bar ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: primary.withValues(alpha: 0.15),
                color: pct == 1.0 ? TagColors.taken : primary,
              ),
            ),

            const SizedBox(height: 10),

            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                HomeChip(label: '${stats.taken} taken', color: TagColors.taken),
                const SizedBox(width: 6),
                if (stats.pending > 0)
                  HomeChip(label: '${stats.pending} left', color: primary),
                if (stats.pending > 0) const SizedBox(width: 6),
                if (stats.skipped > 0)
                  HomeChip(label: '${stats.skipped} skipped', color: TagColors.skipped),
                const Spacer(),
                Text(
                  '${(pct * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: pct == 1.0 ? TagColors.taken : primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Motivational message ───────────────────────────────────
            Text(
              motiveLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _motiveLine(double pct, DayStats s) {
    if (s.total == 0) return 'No doses scheduled today.';
    if (pct == 1.0) return 'All doses done for today!';
    if (s.taken == 0) return 'Start strong — take your first dose!';
    if (pct >= 0.75) return 'Almost there — keep it up!';
    if (pct >= 0.5) return 'Good progress — stay consistent!';
    return 'Stay on track for better health.';
  }

  static String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
