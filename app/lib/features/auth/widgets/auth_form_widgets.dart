import 'package:flutter/material.dart';

import '../../../core/theme/theme_constants.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final Color surface;
  final Color outline;
  final Color muted;
  final String? Function(String?)? validator;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.surface,
    required this.outline,
    required this.muted,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
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
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: muted),
            prefixIcon: Icon(icon, color: muted, size: 20),
            suffixIcon: suffix,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      );
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.primary,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Icon(icon),
          label: Text(isLoading ? 'Please wait…' : label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
          ),
        ),
      );
}

class AuthGoogleButton extends StatelessWidget {
  final bool isLoading;
  final Color surface;
  final Color muted;
  final Color outline;
  final VoidCallback onPressed;

  const AuthGoogleButton({
    super.key,
    required this.isLoading,
    required this.surface,
    required this.muted,
    required this.outline,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text(
            'G',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4)),
          ),
          const SizedBox(width: 10),
          Text('Continue with Google',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: muted)),
        ]),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  final Color muted;
  const AuthOrDivider({super.key, required this.muted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Expanded(child: Divider(color: muted.withValues(alpha: 0.3))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or',
            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ),
      Expanded(child: Divider(color: muted.withValues(alpha: 0.3))),
    ]);
  }
}
