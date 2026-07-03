import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/auth_form_widgets.dart';

/// Change password for an already-logged-in user (knows their current
/// password) — verified server-side by medremind_change_password.php.
/// Different from the forgot-password (P5) OTP-based reset flow, which is
/// for a user who isn't logged in.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
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
    final ok = await ref.read(userAuthProvider.notifier).changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed'),
      ));
      Navigator.of(context).pop();
    } else {
      final error = ref.read(userAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Could not change password'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userAuthProvider).isLoading;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DarkColors.background : LightColors.background;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;
    final outline = isDark ? DarkColors.outline : LightColors.outline;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              padding: const EdgeInsets.all(10),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.12),
                border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.password_rounded, color: primary, size: 34),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            Text('Change Password',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              'Enter your current password and choose a new one',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Form(
              key: _formKey,
              child: Column(children: [
                AuthInputField(
                  controller: _currentCtrl,
                  hint: 'Current password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureCurrent,
                  surface: surface,
                  outline: outline,
                  muted: muted,
                  suffix: IconButton(
                    icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: muted,
                        size: 20),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                AuthInputField(
                  controller: _newCtrl,
                  hint: 'New password (min 6 chars)',
                  icon: Icons.lock_reset_rounded,
                  obscure: _obscureNew,
                  surface: surface,
                  outline: outline,
                  muted: muted,
                  suffix: IconButton(
                    icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: muted,
                        size: 20),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a new password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    if (v == _currentCtrl.text) {
                      return 'New password must differ from the current one';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMd),
                AuthInputField(
                  controller: _confirmCtrl,
                  hint: 'Confirm new password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  surface: surface,
                  outline: outline,
                  muted: muted,
                  suffix: IconButton(
                    icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: muted,
                        size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: AppSizes.paddingXl),
                AuthPrimaryButton(
                  label: 'Change Password',
                  icon: Icons.check_rounded,
                  primary: primary,
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
