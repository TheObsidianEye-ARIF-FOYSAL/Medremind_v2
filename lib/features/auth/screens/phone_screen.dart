import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).sendOtp(_ctrl.text.trim());
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: TagColors.missed,
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(phone: _ctrl.text.trim()),
      ));
    }
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
            // ── Back button ─────────────────────────────────────────────────
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              padding: const EdgeInsets.all(10),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.12),
                border: Border.all(color: primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.smartphone_rounded, color: primary, size: 34),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            Text('Enter Your Mobile',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              "We'll send an OTP to your Robi/Airtel number\nfor subscription verification",
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: muted, height: 1.5),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Phone input ─────────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(children: [
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: outline),
                  ),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🇧🇩',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 24, color: outline),
                      ]),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _ctrl,
                        keyboardType: TextInputType.phone,
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 4),
                        ),
                        validator: (v) {
                          final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          if (d.length < 11) return 'Enter 11-digit number';
                          final prefix = d.substring(0, 3);
                          if (prefix != '018' && prefix != '016') {
                            return 'Robi (018) or Airtel (016) only';
                          }
                          return null;
                        },
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: muted),
                  const SizedBox(width: 4),
                  Text('Supported: Robi (018) & Airtel (016) only',
                      style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                ]),
              ]),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Send OTP button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _sendOtp,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(isLoading ? 'Sending…' : 'Send OTP',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            // ── Billing notice ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant),
              ),
              child: Row(children: [
                Icon(Icons.verified_rounded,
                    color: TagColors.taken, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '৳2.78 (Robi) / ৳5.56 (Airtel) +VAT+SD+SC/day\n'
                    'via Robi/Airtel mobile billing',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
