import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../widgets/settings_tiles.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        children: [
          // ── Theme Mode ─────────────────────────────────────────────────────
          SettingsSectionHeader('Theme Mode', icon: Icons.brightness_6_rounded),
          const SizedBox(height: AppSizes.paddingMd),
          SettingsCard(
            isDark: isDark,
            child: Column(
              children: ThemeMode.values.map((mode) {
                return SettingsRadioTile(
                  title: _modeLabel(mode),
                  subtitle: _modeSubtitle(mode),
                  selected: settings.mode == mode,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => notifier.setMode(mode),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSizes.paddingXl),

          // ── Color Theme ────────────────────────────────────────────────────
          SettingsSectionHeader('Color Theme', icon: Icons.palette_rounded),
          const SizedBox(height: AppSizes.paddingMd),
          SettingsCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose an accent colour for the entire app.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  // Two rows of 3
                  _PaletteGrid(
                    selected: settings.palette,
                    onSelect: notifier.setPalette,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  String _modeSubtitle(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Follows your device setting',
        ThemeMode.light => 'Always use light theme',
        ThemeMode.dark => 'Always use dark theme',
      };
}

// ── Palette grid ──────────────────────────────────────────────────────────────

class _PaletteGrid extends StatelessWidget {
  final AppColorPalette selected;
  final ValueChanged<AppColorPalette> onSelect;
  final bool isDark;

  const _PaletteGrid({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final palettes = AppColorPalette.values;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: palettes
          .map((p) => _PaletteChip(
                palette: p,
                isSelected: selected == p,
                isDark: isDark,
                onTap: () => onSelect(p),
              ))
          .toList(),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final AppColorPalette palette;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PaletteChip({
    required this.palette,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isDark ? palette.primaryLight : palette.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 90,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 34 : 28,
              height: isSelected ? 34 : 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
