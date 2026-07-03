import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../../../auth/providers/user_auth_provider.dart';
import '../../../auth/screens/change_password_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    final user = ref.watch(userAuthProvider).user;
    final name = user?.name ?? '';
    final phone = user?.phone ?? 'Not available';
    final hasName = name.isNotEmpty;
    final subscriptionLabel = user == null
        ? 'Unknown'
        : (user.isSubscribed ? 'Active' : 'Inactive');
    final subscriptionExpiry = user?.subscriptionExpiry;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('My Profile',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: hasName
                          ? Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  Center(
                    child: Text(
                      hasName ? name : 'No name set',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Center(
                    child: Text(phone,
                        style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  _SectionLabel('Account Details'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    label: 'Mobile Number',
                    value: phone,
                    isDark: isDark,
                    primary: primary,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _InfoTile(
                    icon: Icons.verified_rounded,
                    label: 'Subscription',
                    value: subscriptionExpiry != null
                        ? '$subscriptionLabel · expires ${_formatDate(subscriptionExpiry)}'
                        : subscriptionLabel,
                    isDark: isDark,
                    primary: primary,
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  const _AccountActions(),

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Account actions (Logout / Delete) ─────────────────────────────────────────

class _AccountActions extends ConsumerWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divColor =
        isDark ? DarkColors.outlineVariant : LightColors.outlineVariant;

    final notifier = ref.read(userAuthProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(children: [
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          subtitle: 'Sign out of this device',
          color: primary,
          isDark: isDark,
          onTap: () async {
            final ok = await _confirm(context,
                title: 'Logout?',
                message: 'You will be signed out and redirected to the login screen.',
                confirmLabel: 'Logout');
            if (ok) await notifier.logout();
          },
        ),
        Divider(height: 1, color: divColor),

        _ActionTile(
          icon: Icons.password_rounded,
          label: 'Change Password',
          subtitle: 'Update the password for your account',
          color: primary,
          isDark: isDark,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ChangePasswordScreen(),
          )),
        ),
        Divider(height: 1, color: divColor),

        _ActionTile(
          icon: Icons.delete_forever_rounded,
          label: 'Unsubscribe',
          subtitle: 'Cancel your BDApps subscription and delete your account',
          color: TagColors.missed,
          isDark: isDark,
          onTap: () => _handleUnsubscribe(context, ref, notifier: notifier),
        ),
      ]),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
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
                foregroundColor: destructive ? TagColors.missed : null),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _handleUnsubscribe(
    BuildContext context,
    WidgetRef ref, {
    required UserAuthNotifier notifier,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _warnBox(
              'This will cancel your BDApps subscription and permanently delete your account and all data. '
              "You'll need to register again to use the app."),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: TagColors.missed),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

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
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Unsubscribing…'),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

    final done = await notifier.unsubscribe();

    if (context.mounted) Navigator.of(context).pop(); // close loader

    if (!done && context.mounted) {
      final err = ref.read(userAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Unsubscribe failed'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  static Widget _warnBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TagColors.missed.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TagColors.missed.withValues(alpha: 0.30)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_rounded, color: TagColors.missed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.w600)),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color primary;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ]),
    );
  }
}
