import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/firebase_auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final muted = isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted;

    final fbUser = ref.watch(firebaseAuthProvider).user;
    final bdappsPhone = ref.watch(authProvider).phone;
    final displayName = fbUser?.displayName ?? '';
    final email = fbUser?.email ?? '';
    final hasName = displayName.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DarkColors.outlineVariant
                        : LightColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('My Profile',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                children: [
                  // ── Avatar ──────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: hasName
                          ? Center(
                              child: Text(
                                displayName[0].toUpperCase(),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMd),

                  if (hasName)
                    Center(
                      child: Text(displayName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  if (email.isNotEmpty)
                    Center(
                      child: Text(email,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: muted)),
                    ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // ── Account info ────────────────────────────────────────────
                  _SectionLabel('Account'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_rounded,
                    label: 'BdApps Mobile',
                    value: bdappsPhone ?? 'Not available',
                    isDark: isDark,
                    muted: bdappsPhone == null,
                    primary: primary,
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _InfoTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email.isNotEmpty ? email : 'Not available',
                    isDark: isDark,
                    muted: email.isEmpty,
                    primary: primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool muted;
  final Color primary;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(children: [
        Icon(icon,
            size: 20,
            color: muted ? theme.colorScheme.onSurfaceVariant : primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted ? theme.colorScheme.onSurfaceVariant : null,
                    fontStyle: muted ? FontStyle.italic : null,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}
