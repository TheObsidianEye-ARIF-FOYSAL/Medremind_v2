import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_constants.dart';
import '../../../auth/providers/firebase_auth_provider.dart';
import '../screens/profile_screen.dart';

class SettingsProfileCard extends ConsumerWidget {
  final bool isDark;
  final Color primary;
  final Color onSurfaceVariant;
  final TextTheme textTheme;

  const SettingsProfileCard({
    super.key,
    required this.isDark,
    required this.primary,
    required this.onSurfaceVariant,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fbUser = ref.watch(firebaseAuthProvider).user;
    final displayName = fbUser?.displayName ?? '';
    final email = fbUser?.email ?? '';
    final hasName = displayName.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.22),
              primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: hasName
                ? Center(
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? displayName : 'Set your name',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasName ? null : onSurfaceVariant,
                    fontStyle: hasName ? null : FontStyle.italic,
                  ),
                ),
                Text(
                  email.isNotEmpty ? email : 'View profile & account details',
                  style: textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurfaceVariant),
        ]),
      ),
    );
  }
}
