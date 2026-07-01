import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/firebase_auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    final fbState = ref.watch(firebaseAuthProvider);
    final fbUser = fbState.user;
    final bdappsPhone = ref.watch(authProvider).phone;
    final displayName = fbUser?.displayName ?? '';
    final email = fbUser?.email ?? '';
    final hasName = displayName.isNotEmpty;
    final isGoogleUser = fbUser?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────────
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
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // ── Avatar ──────────────────────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        Container(
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
                                    displayName[0].toUpperCase(),
                                    style:
                                        theme.textTheme.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 44),
                        ),
                        if (isGoogleUser)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? DarkColors.outline
                                        : LightColors.outline,
                                    width: 1.5),
                              ),
                              child: const Center(
                                child: Text('G',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4285F4))),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  Center(
                    child: Text(
                      hasName ? displayName : 'No name set',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (email.isNotEmpty)
                    Center(
                      child: Text(email,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: muted)),
                    ),
                  if (isGoogleUser)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          child: const Text('Google Account',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Account info ────────────────────────────────────────────
                  _SectionLabel('Account Details'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    label: 'BdApps Mobile',
                    value: bdappsPhone ?? 'Not available',
                    isDark: isDark,
                    muted: bdappsPhone == null,
                    primary: primary,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _InfoTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email.isNotEmpty ? email : 'Not available',
                    isDark: isDark,
                    muted: email.isEmpty,
                    primary: primary,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _InfoTile(
                    icon: isGoogleUser
                        ? Icons.account_circle_rounded
                        : Icons.lock_outline_rounded,
                    label: 'Sign-in Method',
                    value: isGoogleUser ? 'Google Account' : 'Email & Password',
                    isDark: isDark,
                    muted: false,
                    primary: primary,
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Change password (email users only) ──────────────────────
                  if (!isGoogleUser) ...[
                    _SectionLabel('Security'),
                    const SizedBox(height: 8),
                    _ChangePasswordCard(isDark: isDark, primary: primary),
                  ] else ...[
                    _SectionLabel('Security'),
                    const SizedBox(height: 8),
                    _GooglePasswordNote(isDark: isDark, primary: primary),
                  ],

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Account actions ──────────────────────────────────────────
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _AccountActions(
                    isDark: isDark,
                    primary: primary,
                    isGoogleUser: isGoogleUser,
                  ),

                  const SizedBox(height: AppSizes.paddingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account actions (Logout / Unsubscribe / Delete) ──────────────────────────

class _AccountActions extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final bool isGoogleUser;

  const _AccountActions({
    required this.isDark,
    required this.primary,
    required this.isGoogleUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divColor =
        isDark ? DarkColors.outlineVariant : LightColors.outlineVariant;

    final authNotifier = ref.read(authProvider.notifier);
    final fbNotifier = ref.read(firebaseAuthProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(children: [
        // ── Logout ─────────────────────────────────────────────────────────
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Logout',
          subtitle: 'Sign out — subscription stays active',
          color: primary,
          isDark: isDark,
          onTap: () async {
            final ok = await _confirm(context,
                title: 'Logout?',
                message:
                    'You will be signed out and redirected to the login screen. Your BdApps subscription remains active.',
                confirmLabel: 'Logout');
            if (ok) await fbNotifier.signOut();
          },
        ),
        Divider(height: 1, color: divColor),

        // ── Unsubscribe ────────────────────────────────────────────────────
        _ActionTile(
          icon: Icons.unsubscribe_rounded,
          label: 'Unsubscribe',
          subtitle: 'Cancel BdApps subscription and sign out',
          color: Colors.orange,
          isDark: isDark,
          onTap: () async {
            final ok = await _confirm(context,
                title: 'Unsubscribe?',
                message:
                    'Your BdApps subscription will be cancelled. You will need to subscribe again to use the app.',
                confirmLabel: 'Unsubscribe',
                destructive: true);
            if (!ok || !context.mounted) return;
            final unsubOk = await authNotifier.unsubscribe();
            if (unsubOk) {
              await fbNotifier.signOut();
            } else if (context.mounted) {
              final err = ref.read(authProvider).error;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err ?? 'Unsubscribe failed')),
              );
            }
          },
        ),
        Divider(height: 1, color: divColor),

        // ── Delete Account ─────────────────────────────────────────────────
        _ActionTile(
          icon: Icons.delete_forever_rounded,
          label: 'Delete Account',
          subtitle: 'Permanently delete your account and all data',
          color: TagColors.missed,
          isDark: isDark,
          onTap: () => _handleDelete(context, ref,
              authNotifier: authNotifier,
              fbNotifier: fbNotifier,
              isGoogleUser: isGoogleUser),
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

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref, {
    required AuthNotifier authNotifier,
    required FirebaseAuthNotifier fbNotifier,
    required bool isGoogleUser,
  }) async {
    String? password;

    if (!isGoogleUser) {
      final ctrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _warnBox(
                'This will permanently delete your account, all data, and cancel your BdApps subscription.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ]),
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
      if (confirmed != true || !context.mounted) return;
      password = ctrl.text;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: _warnBox(
              'This will permanently delete your account, all data, and cancel your BdApps subscription. You will be asked to sign in with Google to confirm.'),
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
      if (confirmed != true || !context.mounted) return;
    }

    // Loading overlay
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
                  Text('Deleting account…'),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

    await authNotifier.unsubscribe();
    final deleted = await fbNotifier.deleteAccount(password: password);

    if (context.mounted) Navigator.of(context).pop(); // close loader

    if (!deleted && context.mounted) {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Account deletion failed'),
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

// ── Change password card ──────────────────────────────────────────────────────

class _ChangePasswordCard extends ConsumerStatefulWidget {
  final bool isDark;
  final Color primary;

  const _ChangePasswordCard({required this.isDark, required this.primary});

  @override
  ConsumerState<_ChangePasswordCard> createState() =>
      _ChangePasswordCardState();
}

class _ChangePasswordCardState extends ConsumerState<_ChangePasswordCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(firebaseAuthProvider.notifier)
        .changePassword(_currentCtrl.text, _newCtrl.text);
    if (!mounted) return;
    if (ok) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _expanded = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Password changed successfully'),
        ]),
        backgroundColor: TagColors.taken,
      ));
    } else {
      final err = ref.read(firebaseAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Password change failed'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(firebaseAuthProvider).isLoading;
    final surface = widget.isDark ? DarkColors.surface : LightColors.surface;
    final outline =
        widget.isDark ? DarkColors.outline : LightColors.outline;
    final muted = widget.isDark
        ? DarkColors.onSurfaceMuted
        : LightColors.onSurfaceMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: _expanded
              ? widget.primary.withValues(alpha: 0.35)
              : outline,
        ),
        boxShadow: _expanded
            ? [
                BoxShadow(
                  color: widget.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          // ── Header row ───────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      color: widget.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change Password',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text('Update your account password',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: muted)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      Icon(Icons.expand_more_rounded, color: muted, size: 22),
                ),
              ]),
            ),
          ),

          // ── Expanded form ────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd, 0,
                  AppSizes.paddingMd, AppSizes.paddingMd),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  Divider(height: 1, color: outline),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Current password
                  _PassField(
                    ctrl: _currentCtrl,
                    hint: 'Current password',
                    obscure: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    surface: surface,
                    outline: outline,
                    muted: muted,
                    theme: theme,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  // New password
                  _PassField(
                    ctrl: _newCtrl,
                    hint: 'New password',
                    obscure: _obscureNew,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    surface: surface,
                    outline: outline,
                    muted: muted,
                    theme: theme,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter new password';
                      if (v.length < 6) return 'Minimum 6 characters';
                      if (v == _currentCtrl.text) {
                        return 'New password must differ from current';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingSm),

                  // Confirm new password
                  _PassField(
                    ctrl: _confirmCtrl,
                    hint: 'Confirm new password',
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    surface: surface,
                    outline: outline,
                    muted: muted,
                    theme: theme,
                    validator: (v) =>
                        v != _newCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Password strength hint
                  _StrengthHint(password: _newCtrl.text, muted: muted, theme: theme),
                  const SizedBox(height: AppSizes.paddingMd),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(isLoading ? 'Updating…' : 'Update Password',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Google password note ──────────────────────────────────────────────────────

class _GooglePasswordNote extends StatelessWidget {
  final bool isDark;
  final Color primary;
  const _GooglePasswordNote({required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
            color: const Color(0xFF4285F4).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Text('G',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Google Account',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              'Your password is managed by Google. Visit myaccount.google.com to change it.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Password strength indicator ───────────────────────────────────────────────

class _StrengthHint extends StatelessWidget {
  final String password;
  final Color muted;
  final ThemeData theme;
  const _StrengthHint(
      {required this.password, required this.muted, required this.theme});

  (String, Color, double) get _strength {
    if (password.isEmpty) return ('', muted, 0);
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) score++;
    return switch (score) {
      0 || 1 => ('Weak', TagColors.missed, 0.25),
      2 => ('Fair', TagColors.snoozed, 0.55),
      3 => ('Good', TagColors.taken, 0.8),
      _ => ('Strong', TagColors.taken, 1.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final (label, color, fraction) = _strength;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Strength: ',
            style: theme.textTheme.labelSmall?.copyWith(color: muted)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: fraction,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ),
    ]);
  }
}

// ── Password field ────────────────────────────────────────────────────────────

class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final Color surface, outline, muted;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const _PassField({
    required this.ctrl,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.surface,
    required this.outline,
    required this.muted,
    required this.theme,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: outline),
        ),
        child: TextFormField(
          controller: ctrl,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: muted),
            prefixIcon:
                Icon(Icons.lock_outline_rounded, color: muted, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: muted,
                  size: 18),
              onPressed: onToggle,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            isDense: true,
          ),
        ),
      );
}

// ── Info tile ─────────────────────────────────────────────────────────────────

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
  final bool muted;
  final Color primary;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
    this.muted = false,
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
        Icon(icon,
            size: 20,
            color: muted ? theme.colorScheme.onSurfaceVariant : primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        muted ? theme.colorScheme.onSurfaceVariant : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}
