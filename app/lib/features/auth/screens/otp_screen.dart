import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  /// Called after the BDApps OTP itself verifies successfully. Return true
  /// once the caller's own follow-up work (e.g. creating the Firestore user
  /// via [userAuthProvider]) has also succeeded, to pop back to the root;
  /// return false to stay on this screen and show [followUpError].
  final Future<bool> Function()? onVerified;
  final String Function()? followUpError;

  const OtpScreen({
    super.key,
    required this.phone,
    this.onVerified,
    this.followUpError,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _finishing = false;

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    final ok = await ref.read(authProvider.notifier).verifyOtp(_code);
    if (!mounted) return;
    if (ok) {
      if (widget.onVerified == null) {
        // Pop the entire auth navigator stack back to root.
        // main.dart watches authProvider and will transition to the next flow step.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _finishing = true);
      final done = await widget.onVerified!();
      if (!mounted) return;
      setState(() => _finishing = false);
      if (done) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(widget.followUpError?.call() ?? 'Could not create account.'),
          backgroundColor: TagColors.missed,
        ));
      }
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Invalid OTP. Please try again.'),
        backgroundColor: TagColors.missed,
      ));
      for (final c in _ctrls) { c.clear(); }
      _nodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading || _finishing;
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
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back ──────────────────────────────────────────────────────
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

              Text('Verify Phone',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: muted, height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.phone,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingXl),

              // ── 6-box OTP input ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return Container(
                    width: 48,
                    height: 60,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: outline, width: 1.5),
                    ),
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          _nodes[i + 1].requestFocus();
                        }
                        if (v.isNotEmpty && i == 5) { _verify(); }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSizes.paddingXl),

              // ── Verify button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Verify OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: AppSizes.paddingMd),

              Center(
                child: Text(
                  'Enter the OTP sent to your number',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
