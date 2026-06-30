import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../providers/settings_provider.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_tiles.dart';

export '../providers/settings_provider.dart' show userNameProvider;

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
            const SizedBox(height: AppSizes.paddingMd),

            // ── Profile card ────────────────────────────────────────────────
            SettingsProfileCard(
              isDark: isDark,
              primary: theme.colorScheme.primary,
              onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
              textTheme: theme.textTheme,
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Appearance section ──────────────────────────────────────────
            SettingsSectionHeader('Appearance', icon: Icons.palette_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            // Theme mode
            SettingsCard(
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
                    (mode) => SettingsRadioTile(
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
            SettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color Theme', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSizes.paddingMd),
                    Row(
                      children: AppColorPalette.values
                          .map((p) => Expanded(
                                child: SettingsPaletteTile(
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

            // ── Notifications & permissions ─────────────────────────────────
            SettingsSectionHeader('Notifications & Alarms',
                icon: Icons.notifications_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  SettingsPermissionTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    subtitle: 'Required for dose reminders',
                    permission: Permission.notification,
                    primaryColor: theme.colorScheme.primary,
                    isDark: isDark,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? DarkColors.outlineVariant
                          : LightColors.outlineVariant),
                  SettingsPermissionTile(
                    icon: Icons.alarm_rounded,
                    label: 'Exact alarms',
                    subtitle: 'Required for on-time alarm ringing',
                    permission: Permission.scheduleExactAlarm,
                    primaryColor: theme.colorScheme.primary,
                    isDark: isDark,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? DarkColors.outlineVariant
                          : LightColors.outlineVariant),
                  SettingsPermissionTile(
                    icon: Icons.battery_saver_rounded,
                    label: 'Battery optimization',
                    subtitle: 'Keep alarms alive in background',
                    permission: Permission.ignoreBatteryOptimizations,
                    primaryColor: theme.colorScheme.primary,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── About section ───────────────────────────────────────────────
            SettingsSectionHeader('About', icon: Icons.info_outline_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  SettingsInfoTile(
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
                  SettingsInfoTile(
                    icon: Icons.layers_rounded,
                    label: 'Build',
                    value: 'Phases 0–6',
                    primaryColor: theme.colorScheme.primary,
                  ),
                  Divider(
                      height: 1,
                      color: isDark
                          ? DarkColors.outlineVariant
                          : LightColors.outlineVariant),
                  SettingsInfoTile(
                    icon: Icons.place_rounded,
                    label: 'Region',
                    value: 'Bangladesh',
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
