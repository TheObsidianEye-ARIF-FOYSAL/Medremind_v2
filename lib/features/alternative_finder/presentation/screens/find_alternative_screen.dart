import 'package:flutter/material.dart';
import '../../../../core/theme/theme_constants.dart';

class FindAlternativeScreen extends StatelessWidget {
  const FindAlternativeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg, AppSizes.paddingLg,
                  AppSizes.paddingLg, 0),
              child: Text(
                'Find Alternative',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by brand name (e.g. Napa)…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        size: 44,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Generic / Brand Finder',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Coming in Phase 5\nType a brand name to find\nall generics and alternatives',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? DarkColors.onSurfaceMuted
                            : LightColors.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
