import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/forgot_password_provider.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/auth_form_widgets.dart';
import 'reset_password_screen.dart';

/// Second step for an existing phone number: password entry, verified
/// server-side by medremind_login.php against the stored password hash.
class LoginPasswordScreen extends ConsumerStatefulWidget {
  final String phone;
  const LoginPasswordScreen({super.key, required this.phone});

  @override
  ConsumerState<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends ConsumerState<LoginPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(userAuthProvider.notifier)
        .login(phone: widget.phone, password: _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      // main.dart watches userAuthProvider and advances the flow.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = ref.read(userAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Login failed'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  Future<void> _forgotPassword() async {
    final ok = await ref
        .read(forgotPasswordProvider.notifier)
        .requestReset(widget.phone);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(phone: widget.phone),
      ));
    } else {
      final error = ref.read(forgotPasswordProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Could not send OTP'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userAuthProvider).isLoading ||
        ref.watch(forgotPasswordProvider).isLoading;
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
              child: Icon(Icons.lock_outline_rounded, color: primary, size: 34),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            Text('Welcome Back',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
                children: [
                  const TextSpan(text: 'Enter the password for\n'),
                  TextSpan(
                    text: widget.phone,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Form(
              key: _formKey,
              child: Column(children: [
                AuthInputField(
                  controller: _passCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  surface: surface,
                  outline: outline,
                  muted: muted,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: muted,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                ),
                const SizedBox(height: AppSizes.paddingSm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                AuthPrimaryButton(
                  label: 'Login',
                  icon: Icons.login_rounded,
                  primary: primary,
                  isLoading: isLoading,
                  onPressed: _login,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
