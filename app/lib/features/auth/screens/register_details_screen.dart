import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/auth_form_widgets.dart';
import 'otp_screen.dart';

/// First half of registration for a phone number not yet in Firestore: name
/// + password. Submitting sends a BDApps OTP; the Firestore user document
/// (with hashed password) is only created once that OTP is verified.
class RegisterDetailsScreen extends ConsumerStatefulWidget {
  final String phone;
  const RegisterDetailsScreen({super.key, required this.phone});

  @override
  ConsumerState<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends ConsumerState<RegisterDetailsScreen> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: TagColors.missed,
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OtpScreen(
        phone: widget.phone,
        onVerified: () => ref.read(userAuthProvider.notifier).register(
              phone: widget.phone,
              name: _nameCtrl.text.trim(),
              password: _passCtrl.text,
            ),
        followUpError: () => ref.read(userAuthProvider).error ?? 'Could not create account.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
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

            Text('Create Your Account',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
                children: [
                  const TextSpan(text: 'New account for\n'),
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
                  controller: _nameCtrl,
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  surface: surface,
                  outline: outline,
                  muted: muted,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                AuthInputField(
                  controller: _passCtrl,
                  hint: 'Password (min 6 chars)',
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
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMd),
                AuthInputField(
                  controller: _confirmCtrl,
                  hint: 'Confirm password',
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
                  label: 'Send OTP',
                  icon: Icons.sms_rounded,
                  primary: primary,
                  isLoading: isLoading,
                  onPressed: _sendOtp,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
