import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/app_settings_service.dart';
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
    final appSettings = ref.watch(appSettingsProvider);
    final appSettingsNotifier = ref.read(appSettingsProvider.notifier);
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

            // ── Reminder behaviour ──────────────────────────────────────────
            SettingsSectionHeader('Reminder Behaviour',
                icon: Icons.tune_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            SettingsCard(
              isDark: isDark,
              child: Column(children: [
                // Notification toggle
                _ToggleTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Push Notifications',
                  subtitle: 'Show a silent notification when it\'s dose time',
                  value: appSettings.notificationEnabled,
                  primaryColor: theme.colorScheme.primary,
                  isDark: isDark,
                  onChanged: appSettingsNotifier.setNotificationEnabled,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant),
                // Alarm toggle
                _ToggleTile(
                  icon: Icons.alarm_rounded,
                  label: 'Ringing Alarm',
                  subtitle: 'Play alarm sound and show full-screen alert',
                  value: appSettings.alarmEnabled,
                  primaryColor: theme.colorScheme.primary,
                  isDark: isDark,
                  onChanged: appSettingsNotifier.setAlarmEnabled,
                ),
              ]),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            // Alarm sound picker
            SettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(Icons.music_note_rounded,
                            size: 18,
                            color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alarm Sound',
                                  style: theme.textTheme.bodyMedium),
                              Text(
                                appSettings.alarmSoundLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant),
                              ),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.paddingMd),
                    ...alarmSoundOptions.map((opt) => _SoundTile(
                          option: opt,
                          isSelected:
                              appSettings.alarmSoundPath == opt.assetPath,
                          primaryColor: theme.colorScheme.primary,
                          isDark: isDark,
                          onTap: () =>
                              appSettingsNotifier.setAlarmSound(opt.assetPath),
                        )),
                  ],
                ),
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
