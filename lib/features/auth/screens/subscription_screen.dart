import 'package:flutter/material.dart';

import 'phone_screen.dart';

// ── Subscription / landing screen ─────────────────────────────────────────────
// Design matches bdapps login guidelines:
//   - App name, pricing (2.78/5.56 BDT + VAT+SC+SD), feature list
//   - Robi (018) & Airtel (016) only
//   - "Subscribe with Mobile" → phone entry → OTP

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── App icon ───────────────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [
                      Color(0xFF7C6EEA),
                      Color(0xFF5547C8),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C6EEA).withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.medication_rounded,
                      color: Colors.white, size: 48),
                ),

                const SizedBox(height: 20),

                // ── App name & tagline ─────────────────────────────────────
                const Text(
                  'MedRemind',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your Smart Medicine Reminder',
                  style: TextStyle(
                    color: Color(0xFFAAAFD8),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Pricing card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF7C6EEA).withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(children: [
                    Text('ONLY',
                        style: TextStyle(
                            color: Color(0xFFAAAFD8),
                            fontSize: 12,
                            letterSpacing: 2)),
                    SizedBox(height: 4),
                    Text(
                      '৳2.78 / ৳5.56',
                      style: TextStyle(
                        color: Color(0xFF7EE8C8),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '+VAT+SD+SC per day',
                      style: TextStyle(
                          color: Color(0xFFAAAFD8), fontSize: 13),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                // ── Feature list ───────────────────────────────────────────
                ..._features.map((f) => _FeatureTile(
                    icon: f.$1, title: f.$2, subtitle: f.$3)),

                const SizedBox(height: 32),

                // ── Subscribe button ───────────────────────────────────────
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
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PhoneScreen()),
                      ),
                      icon: const Icon(Icons.smartphone_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Subscribe with Mobile',
                        style: TextStyle(
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

                const SizedBox(height: 16),

                // ── Network notice ─────────────────────────────────────────
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

                const SizedBox(height: 12),

                const Text(
                  'Supported: Android | Robi (018) & Airtel (016) only',
                  style: TextStyle(color: Color(0xFF7A7DAA), fontSize: 11),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Feature tuples: (icon, title, subtitle)
const _features = [
  (Icons.alarm_rounded, 'Never Miss a Dose',
      'Full-screen alarm with sound even when screen is off'),
  (Icons.medication_liquid_rounded, 'Medicine Cabinet',
      'Track all medicines with dosage and schedule'),
  (Icons.bar_chart_rounded, 'Adherence History',
      'View daily & weekly dose-taking statistics'),
];

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1860).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF7C6EEA).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C6EEA).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF9B8EF0), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFAAAFD8), fontSize: 12)),
                ]),
          ),
        ]),
      );
}
