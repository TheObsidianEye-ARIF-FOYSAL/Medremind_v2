import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/forgot_password_provider.dart';
import '../widgets/auth_form_widgets.dart';

/// P5 Forgot password, step 2: the BDApps OTP for [phone] has already been
/// requested (see ForgotPasswordNotifier.requestReset, called before this
/// screen is pushed). User enters the OTP and a new password together —
/// fp_reset_password.php verifies both in one call.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phone;
  const ResetPasswordScreen({super.key, required this.phone});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    for (final c in _otpCtrls) { c.dispose(); }
    for (final n in _otpNodes) { n.dispose(); }
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpCtrls.map((c) => c.text).join();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter the 6-digit OTP'),
        backgroundColor: TagColors.missed,
      ));
      return;
    }
    final ok = await ref.read(forgotPasswordProvider.notifier).resetPassword(
          otp: _otp,
          newPassword: _passCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset. Please log in with your new password.'),
      ));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final error = ref.read(forgotPasswordProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Could not reset password'),
        backgroundColor: TagColors.missed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(forgotPasswordProvider).isLoading;
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

            Text('Reset Password',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
                children: [
                  const TextSpan(text: 'Enter the OTP sent to\n'),
                  TextSpan(
                    text: widget.phone,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '\nand choose a new password'),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  height: 60,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: outline, width: 1.5),
                  ),
                  child: TextField(
                    controller: _otpCtrls[i],
                    focusNode: _otpNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) _otpNodes[i + 1].requestFocus();
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Form(
              key: _formKey,
              child: Column(children: [
                AuthInputField(
                  controller: _passCtrl,
                  hint: 'New password (min 6 chars)',
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a new password';
                    if (v.length < 6) return 'Minimum 6 characters';
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
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: AppSizes.paddingXl),
                AuthPrimaryButton(
                  label: 'Reset Password',
                  icon: Icons.lock_reset_rounded,
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
