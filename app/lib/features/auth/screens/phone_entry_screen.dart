import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/user_auth_provider.dart';
import 'login_password_screen.dart';
import 'register_details_screen.dart';

/// First step of the unified phone+password login: user enters their number,
/// we check Firestore (via Cloud Function) for an existing account, and
/// route to login or registration accordingly.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _ctrl.text.trim();
    try {
      final exists = await ref.read(userAuthProvider.notifier).checkPhoneExists(phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            exists ? LoginPasswordScreen(phone: phone) : RegisterDetailsScreen(phone: phone),
      ));
    } catch (_) {
      if (!mounted) return;
      final error = ref.read(userAuthProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Something went wrong. Please try again.'),
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
            const SizedBox(height: AppSizes.paddingXl),

            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.13),
                border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.medication_rounded, color: primary, size: 40),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            Text('Welcome to MedRemind',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              "Enter your mobile number to sign in or create an account",
              style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: outline),
                ),
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🇧🇩', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 24, color: outline),
                    ]),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        hintStyle: TextStyle(color: muted),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      ),
                      validator: (v) {
                        final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        if (d.length != 11) return 'Enter 11-digit number';
                        return null;
                      },
                    ),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _continue,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(isLoading ? 'Checking…' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
