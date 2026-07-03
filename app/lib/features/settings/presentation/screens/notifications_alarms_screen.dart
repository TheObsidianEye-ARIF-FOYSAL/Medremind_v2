import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';
import '../widgets/settings_tiles.dart';

class NotificationsAlarmsScreen extends ConsumerWidget {
  const NotificationsAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final appSettings = ref.watch(appSettingsProvider);
    final appSettingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alarms'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        children: [
          // ── Android permissions ────────────────────────────────────────────
          SettingsSectionHeader('Android Permissions',
              icon: Icons.verified_user_rounded),
          const SizedBox(height: AppSizes.paddingMd),

          SettingsCard(
            isDark: isDark,
            child: Column(children: [
              SettingsPermissionTile(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                subtitle: 'Required for dose reminders',
                permission: Permission.notification,
                primaryColor: primary,
                isDark: isDark,
              ),
              _divider(isDark),
              SettingsPermissionTile(
                icon: Icons.alarm_rounded,
                label: 'Exact Alarms',
                subtitle: 'Required for on-time alarm ringing',
                permission: Permission.scheduleExactAlarm,
                primaryColor: primary,
                isDark: isDark,
              ),
              _divider(isDark),
              SettingsPermissionTile(
                icon: Icons.battery_saver_rounded,
                label: 'Battery Optimization',
                subtitle: 'Keep alarms alive in background',
                permission: Permission.ignoreBatteryOptimizations,
                primaryColor: primary,
                isDark: isDark,
              ),
            ]),
          ),

          const SizedBox(height: AppSizes.paddingXl),

          // ── Reminder behaviour ─────────────────────────────────────────────
          SettingsSectionHeader('Reminder Behaviour',
              icon: Icons.tune_rounded),
          const SizedBox(height: AppSizes.paddingMd),

          SettingsCard(
            isDark: isDark,
            child: Column(children: [
              _ToggleTile(
                icon: Icons.notifications_active_rounded,
                label: 'Push Notifications',
                subtitle: 'Show a silent notification when it\'s dose time',
                value: appSettings.notificationEnabled,
                primaryColor: primary,
                isDark: isDark,
                onChanged: appSettingsNotifier.setNotificationEnabled,
              ),
              _divider(isDark),
              _ToggleTile(
                icon: Icons.alarm_rounded,
                label: 'Ringing Alarm',
                subtitle: 'Play alarm sound and show full-screen alert',
                value: appSettings.alarmEnabled,
                primaryColor: primary,
                isDark: isDark,
                onChanged: (v) => _setAlarmEnabled(ref, v),
              ),
            ]),
          ),

          const SizedBox(height: AppSizes.paddingMd),

          // Info card
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Turning off "Ringing Alarm" disables the full-screen alarm and sound. '
                    'Turning off "Push Notifications" hides the silent dose reminders. '
                    'Android permissions must also be granted for these features to work.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        color: isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
      );

  /// Toggling this off cancels every currently-scheduled alarm immediately
  /// (not just future ones); toggling back on reschedules all active dose
  /// groups. Without this, the setting would only affect alarms scheduled
  /// *after* the toggle changed, leaving already-scheduled ones ringing.
  Future<void> _setAlarmEnabled(WidgetRef ref, bool enabled) async {
    await ref.read(appSettingsProvider.notifier).setAlarmEnabled(enabled);
    if (!enabled) {
      await alarmService.cancelAll();
    } else {
      final groups =
          await ref.read(doseGroupRepositoryProvider).getAll(activeOnly: true);
      await alarmService.rescheduleAll(groups);
    }
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color primaryColor;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.primaryColor,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (value ? primaryColor : theme.colorScheme.onSurfaceVariant)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon,
              size: 18,
              color:
                  value ? primaryColor : theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: primaryColor,
        ),
      ]),
    );
  }
}
