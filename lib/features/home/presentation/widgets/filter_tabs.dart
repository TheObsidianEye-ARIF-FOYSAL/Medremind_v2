import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';

// ── Time filter ────────────────────────────────────────────────────────────────

enum TimeFilter { all, morning, afternoon, evening, night }

extension TimeFilterX on TimeFilter {
  String get label => ['All', 'Morning', 'Afternoon', 'Evening', 'Night'][index];
  String? get groupLabel =>
      index == 0 ? null : ['Morning', 'Afternoon', 'Evening', 'Night'][index - 1];
}

// ── Filter tabs widget ─────────────────────────────────────────────────────────

class HomeFilterTabs extends StatelessWidget {
  final TimeFilter selected;
  final Color primary;
  final bool isDark;
  final ValueChanged<TimeFilter> onChanged;

  const HomeFilterTabs({
    super.key,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
        children: TimeFilter.values.map((f) {
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
                  f.label,
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
