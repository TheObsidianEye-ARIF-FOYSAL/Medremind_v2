import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../auth/providers/auth_provider.dart'
    show AuthNotifier, authProvider;
import '../../../auth/providers/firebase_auth_provider.dart'
    show FirebaseAuthNotifier, firebaseAuthProvider;
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
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);
    final fbNotifier = ref.read(firebaseAuthProvider.notifier);
    final fbUser = ref.watch(firebaseAuthProvider).user;
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

            // ── Account section ─────────────────────────────────────────────
            SettingsSectionHeader('Account',
                icon: Icons.account_circle_rounded),
            const SizedBox(height: AppSizes.paddingMd),

            SettingsCard(
              isDark: isDark,
              child: Column(children: [
                // ── Logout (Firebase only — keeps BdApps subscription)
                _AccountTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  subtitle: 'Sign out — subscription stays active',
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                  onTap: () async {
                    final confirm = await _confirmDialog(
                      context,
                      title: 'Logout?',
                      message:
                          'You will be signed out and redirected to the login screen. Your BdApps subscription remains active.',
                      confirmLabel: 'Logout',
                    );
                    if (confirm == true) await fbNotifier.signOut();
                  },
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant),
                // ── Unsubscribe (BdApps + Firebase signOut)
                _AccountTile(
                  icon: Icons.unsubscribe_rounded,
                  label: 'Unsubscribe',
                  subtitle: 'Cancel BdApps subscription and sign out',
                  color: Colors.orange,
                  isDark: isDark,
                  onTap: () async {
                    final confirm = await _confirmDialog(
                      context,
                      title: 'Unsubscribe?',
                      message:
                          'Your BdApps subscription will be cancelled. You will need to subscribe again to use the app.',
                      confirmLabel: 'Unsubscribe',
                      destructive: true,
                    );
                    if (confirm == true) {
                      final ok = await authNotifier.unsubscribe();
                      if (ok) {
                        await fbNotifier.signOut();
                      } else if (context.mounted) {
                        final err = ref.read(authProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err ?? 'Unsubscribe failed')),
                        );
                      }
                    }
                  },
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant),
                // ── Delete Account
                _AccountTile(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  color: TagColors.missed,
                  isDark: isDark,
                  onTap: () async => _handleDeleteAccount(
                      context, ref, authNotifier, fbNotifier,
                      isGoogleUser: fbUser != null &&
                          fbUser.providerData
                              .any((p) => p.providerId == 'google.com')),
                ),
              ]),
            ),

            if (authState.phone != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.paddingSm),
                child: Text(
                  'BdApps: ${authState.phone}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

  Future<void> _handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    AuthNotifier authNotifier,
    FirebaseAuthNotifier fbNotifier, {
    required bool isGoogleUser,
  }) async {
    String? password;

    if (!isGoogleUser) {
      // Ask for password confirmation
      final ctrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TagColors.missed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: TagColors.missed.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.warning_rounded,
                      color: TagColors.missed, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will permanently delete your account, all data, and cancel your BdApps subscription.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password to confirm',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: TagColors.missed),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      password = ctrl.text;
    } else {
      // Google user — just confirm
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TagColors.missed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: TagColors.missed.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.warning_rounded,
                      color: TagColors.missed, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will permanently delete your account, all data, and cancel your BdApps subscription. You will be asked to sign in with Google to confirm.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: TagColors.missed),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;

    // Show loading overlay while processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deleting account…'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // 1. Unsubscribe BdApps
    await authNotifier.unsubscribe();

    // 2. Delete Firebase account (re-auths internally)
    final deleted = await fbNotifier.deleteAccount(password: password);

    if (context.mounted) Navigator.of(context).pop(); // close loading

    if (!deleted && context.mounted) {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Account deletion failed'),
          backgroundColor: TagColors.missed,
        ),
      );
    }
    // If deleted, authProvider and firebaseAuthProvider are both cleared,
    // main.dart will detect auth loss and redirect to SubscriptionScreen.
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: destructive ? TagColors.missed : null,
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
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
              color: value
                  ? primaryColor
                  : theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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

// ── Sound tile ────────────────────────────────────────────────────────────────

class _SoundTile extends StatelessWidget {
  final AlarmSoundOption option;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SoundTile({
    required this.option,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 6 : 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.music_note_rounded,
              size: 16,
              color: isSelected
                  ? primaryColor
                  : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? primaryColor : null,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Account action tile ────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
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
            horizontal: AppSizes.paddingMd, vertical: 14),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: color)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}
