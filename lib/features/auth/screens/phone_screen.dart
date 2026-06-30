import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        backgroundColor: const Color(0xFFE05C5C),
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0B2A), Color(0xFF1A1650), Color(0xFF0D0B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back button ────────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1860).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF7C6EEA)
                              .withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Phone icon ─────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [
                      Color(0xFF7C6EEA),
                      Color(0xFF5547C8),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C6EEA)
                            .withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.smartphone_rounded,
                      color: Colors.white, size: 36),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Enter Your Mobile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We'll send an OTP to your Robi/Airtel number\nfor subscription verification",
                  style: TextStyle(color: Color(0xFFAAAFD8), height: 1.5),
                ),

                const SizedBox(height: 32),

                // ── Phone input ────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1860).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF7C6EEA)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      // Flag + prefix
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        child: Row(children: [
                          Image.asset('assets/images/bd_flag.png',
                              width: 24,
                              height: 16,
                              errorBuilder: (_, __, ___) => const Text(
                                    '🇧🇩',
                                    style: TextStyle(fontSize: 16),
                                  )),
                          const SizedBox(width: 8),
                          const Text('|',
                              style: TextStyle(
                                  color: Color(0xFF4A4878), fontSize: 20)),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: '01XXXXXXXXX',
                            hintStyle: TextStyle(color: Color(0xFF5A5888)),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (v) {
                            final d =
                                (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                            if (d.length < 11) return 'Enter 11-digit number';
                            // Robi: 018, Airtel: 016
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
                ),

                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFF7A7DAA)),
                  SizedBox(width: 4),
                  Text(
                    'Supported: Robi (018) & Airtel (016) only',
                    style: TextStyle(color: Color(0xFF7A7DAA), fontSize: 12),
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Send OTP button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF7C6EEA),
                        Color(0xFF5547C8),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C6EEA)
                              .withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _sendOtp,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white),
                      label: Text(
                        isLoading ? 'Sending...' : 'Send OTP',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Subscription info ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF7C6EEA)
                            .withValues(alpha: 0.25)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF7EE8C8), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Subscription: ৳2.78 (Robi) / ৳5.56 (Airtel) '
                        '+VAT+SD+SC/day\nvia Robi/Airtel mobile billing',
                        style: TextStyle(
                            color: Color(0xFFAAAFD8), fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
