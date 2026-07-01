import 'package:flutter/material.dart';

import '../../../core/theme/theme_constants.dart';
import '../providers/firebase_auth_provider.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailCtrl;
  final FirebaseAuthNotifier notifier;

  const ForgotPasswordSheet({
    super.key,
    required this.emailCtrl,
    required this.notifier,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  bool _loading = false;
  bool _sent = false;

  Future<void> _send() async {
    final email = widget.emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid email address'),
          backgroundColor: TagColors.missed));
      return;
    }
    setState(() => _loading = true);
    await widget.notifier.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final bg = isDark ? DarkColors.background : LightColors.background;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final outline = isDark ? DarkColors.outline : LightColors.outline;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: !_sent
                  ? _InputState(
                      key: const ValueKey('input'),
                      emailCtrl: widget.emailCtrl,
                      loading: _loading,
                      primary: primary,
                      surface: surface,
                      outline: outline,
                      muted: muted,
                      theme: theme,
                      onSend: _send,
                    )
                  : _SuccessState(
                      key: const ValueKey('success'),
                      email: widget.emailCtrl.text.trim(),
                      primary: primary,
                      muted: muted,
                      theme: theme,
                    ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
          ],
        ),
      ),
    );
  }
}

class _InputState extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final Color primary;
  final Color surface;
  final Color outline;
  final Color muted;
  final ThemeData theme;
  final VoidCallback onSend;

  const _InputState({
    super.key,
    required this.emailCtrl,
    required this.loading,
    required this.primary,
    required this.surface,
    required this.outline,
    required this.muted,
    required this.theme,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reset Password',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(
        "Enter your email and we'll send a password reset link.",
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      ),
      const SizedBox(height: AppSizes.paddingLg),
      Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: outline),
        ),
        child: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Email address',
            hintStyle: TextStyle(color: muted),
            prefixIcon: Icon(Icons.email_outlined, color: muted, size: 20),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.paddingLg),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : onSend,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Send Reset Link',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

class _SuccessState extends StatelessWidget {
  final String email;
  final Color primary;
  final Color muted;
  final ThemeData theme;

  const _SuccessState({
    super.key,
    required this.email,
    required this.primary,
    required this.muted,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TagColors.taken.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: TagColors.taken, size: 36),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Text('Check your inbox',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'A password reset link has been sent to\n$email',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingXl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
            ),
            child: const Text('Back to Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
