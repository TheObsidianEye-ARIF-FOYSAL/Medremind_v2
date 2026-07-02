import 'package:flutter/material.dart';

import '../../../../core/theme/theme_constants.dart';
import 'phone_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? DarkColors.background : LightColors.background;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLg, vertical: AppSizes.paddingLg),
          child: Column(children: [
            const SizedBox(height: AppSizes.paddingXl),

            // ── App icon ─────────────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.15),
                border: Border.all(color: primary.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.medication_rounded, color: primary, size: 48),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            Text('MedRemind',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 6),
            Text(
              'Your Smart Medicine Reminder',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: muted),
            ),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Pricing card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg, vertical: AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border:
                    Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Column(children: [
                Text('ONLY',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: muted, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(
                  '৳2.78',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('+VAT+SD+SC per day',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              ]),
            ),

            const SizedBox(height: AppSizes.paddingLg),

            // ── Feature list ──────────────────────────────────────────────────
            ..._features.map((f) => _FeatureTile(
                  icon: f.$1,
                  title: f.$2,
                  subtitle: f.$3,
                  surface: surface,
                  primary: primary,
                  muted: muted,
                  theme: theme,
                )),

            const SizedBox(height: AppSizes.paddingXl),

            // ── Subscribe button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PhoneScreen()),
                ),
                icon: const Icon(Icons.smartphone_rounded),
                label: const Text('Subscribe with Mobile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
              ),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            // ── Network / billing notice ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusCard),
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
                    '৳2.78 +VAT+SD+SC/day\n'
                    'via mobile billing',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: AppSizes.paddingMd),

            Text(
              'Supported: Android',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.paddingXl),
          ]),
        ),
      ),
    );
  }
}

const _features = [
  (Icons.alarm_rounded, 'Never Miss a Dose',
      'Full-screen alarm with sound even when your screen is off'),
  (Icons.medication_liquid_rounded, 'Medicine Cabinet',
      'Track all medicines with dosage and daily schedule'),
  (Icons.bar_chart_rounded, 'Adherence History',
      'View daily & weekly dose-taking statistics'),
];

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color surface;
  final Color primary;
  final Color muted;
  final ThemeData theme;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.surface,
    required this.primary,
    required this.muted,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: muted)),
                ]),
          ),
        ]),
      );
}
