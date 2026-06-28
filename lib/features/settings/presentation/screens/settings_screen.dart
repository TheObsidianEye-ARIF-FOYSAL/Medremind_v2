import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, AppSizes.paddingLg,
              AppSizes.paddingLg, 120),
          children: [
            Text('Settings', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSizes.paddingXl),

            // ── Appearance section ──────────────────────────────────────────
            _SectionHeader('Appearance'),
            const SizedBox(height: AppSizes.paddingMd),

            // Theme mode
            _SettingsCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.paddingMd, AppSizes.paddingMd,
                        AppSizes.paddingMd, AppSizes.paddingSm),
                    child: Text(
                      'Theme Mode',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  ...ThemeMode.values.map(
                    (mode) => _RadioTile(
                      title: _themeModeLabel(mode),
                      subtitle: _themeModeSubtitle(mode),
                      selected: settings.mode == mode,
                      activeColor: theme.colorScheme.primary,
                      onTap: () => notifier.setMode(mode),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            // Color palette picker
            _SettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color Theme', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '3 palettes × 2 modes = 6 total theme combinations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    Row(
                      children: AppColorPalette.values
                          .map((p) => Expanded(
                                child: _PaletteTile(
                                  palette: p,
                                  isSelected: settings.palette == p,
                                  onTap: () => notifier.setPalette(p),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── About section ───────────────────────────────────────────────
            _SectionHeader('About'),
            const SizedBox(height: AppSizes.paddingMd),

            _SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.medication_rounded,
                    label: 'MedRemind',
                    value: 'v2.0.0',
                    primaryColor: theme.colorScheme.primary,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? DarkColors.outlineVariant
                          : LightColors.outlineVariant),
                  _InfoTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Phase',
                    value: 'Phase 0 — Scaffold',
                    primaryColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  String _themeModeSubtitle(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Follows your device setting',
      ThemeMode.light => 'Always use light theme',
      ThemeMode.dark => 'Always use dark theme',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final AppColorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 24)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? palette.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: AppSizes.paddingMd),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
