import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/history_provider.dart';

class WeekSummaryCard extends StatelessWidget {
  final WeekSummary summary;
  final bool isDark;
  final Color primary;

  const WeekSummaryCard({
    super.key,
    required this.summary,
    required this.isDark,
    required this.primary,
  });

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
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This week',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: summary.rate),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, val, __) => Text(
                  '${(val * 100).toStringAsFixed(0)}% adherence',
                  style: theme.textTheme.headlineSmall?.copyWith(color: primary),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                StatusPill(label: '${summary.taken} Taken', color: TagColors.taken),
                StatusPill(label: '${summary.missed} Missed', color: TagColors.missed),
                StatusPill(label: '${summary.skipped} Skipped', color: TagColors.skipped),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: summary.rate),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, val, __) => SizedBox(
            width: 60,
            height: 60,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: val,
                strokeWidth: 6,
                backgroundColor: primary.withValues(alpha: 0.15),
                color: primary,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text('$pct%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
      );
}
