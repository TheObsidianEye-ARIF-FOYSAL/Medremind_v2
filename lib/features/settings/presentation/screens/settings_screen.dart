import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_transitions.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/theme_constants.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_tiles.dart';
import 'appearance_screen.dart';
import 'notifications_alarms_screen.dart';
import 'alarm_sound_screen.dart';

export '../providers/settings_provider.dart' show userNameProvider;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    void push(Widget screen) =>
        Navigator.of(context).push(AppFadeRoute(page: screen));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, AppSizes.paddingLg,
              AppSizes.paddingLg, 120),
          children: [
            Text('Settings', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSizes.paddingMd),

            // ── Profile card ────────────────────────────────────────────────
            SettingsProfileCard(
              isDark: isDark,
              primary: primary,
              onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
              textTheme: theme.textTheme,
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Preferences navigation group ────────────────────────────────
            SettingsSectionHeader('Preferences', icon: Icons.tune_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            SettingsCard(
              isDark: isDark,
              child: Column(children: [
                _NavTile(
                  icon: Icons.palette_rounded,
                  iconColor: const Color(0xFF6C5CE7),
                  label: 'Appearance',
                  subtitle: 'Theme mode & colour palette',
                  isDark: isDark,
                  onTap: () => push(const AppearanceScreen()),
                ),
                _divider(isDark),
                _NavTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFF00B4D8),
                  label: 'Notifications & Alarms',
                  subtitle: 'Permissions, toggles & behaviour',
                  isDark: isDark,
                  onTap: () => push(const NotificationsAlarmsScreen()),
                ),
                _divider(isDark),
                _NavTile(
                  icon: Icons.music_note_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Alarm Sound',
                  subtitle: appSettings.alarmSoundLabel,
                  isDark: isDark,
                  onTap: () => push(const AlarmSoundScreen()),
                ),
              ]),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── About section ───────────────────────────────────────────────
            SettingsSectionHeader('About', icon: Icons.info_outline_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            // App description card
            SettingsCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Icon(Icons.medication_liquid_rounded,
                            size: 26, color: primary),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MedRemind',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text('Version 5.9.13  ·  Bangladesh',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: AppSizes.paddingMd),
                    Text(
                      'MedRemind is a smart medicine reminder app designed specifically '
                      'for patients and caregivers in Bangladesh. It helps you schedule '
                      'daily dose groups with precise alarm times, track your medication '
                      'adherence through a colour-coded calendar, and review your full '
                      'dose history — all in one place.\n\n'
                      'You sign in with your mobile number and a password, secured by '
                      'Firebase and Cloud Firestore. Alarms ring even when the screen is '
                      'locked, and action buttons let you dismiss or snooze a reminder '
                      'without unlocking your phone.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            // Build details card
            SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  SettingsInfoTile(
                    icon: Icons.tag_rounded,
                    label: 'Version',
                    value: 'v5.9.13',
                    primaryColor: primary,
                  ),
                  _divider(isDark),
                  SettingsInfoTile(
                    icon: Icons.build_circle_rounded,
                    label: 'Release',
                    value: 'Stable',
                    primaryColor: primary,
                  ),
                  _divider(isDark),
                  SettingsInfoTile(
                    icon: Icons.smartphone_rounded,
                    label: 'Platform',
                    value: 'Android',
                    primaryColor: primary,
                  ),
                  _divider(isDark),
                  SettingsInfoTile(
                    icon: Icons.language_rounded,
                    label: 'Developed for',
                    value: 'Bangladesh',
                    primaryColor: primary,
                  ),
                  _divider(isDark),
                  SettingsInfoTile(
                    icon: Icons.code_rounded,
                    label: 'Built with',
                    value: 'Flutter · Firebase · BdApps',
                    primaryColor: primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        color: isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
      );
}

// ── Navigation tile ───────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd, vertical: 13),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

