import 'package:flutter/material.dart';
import '../../../../core/theme/theme_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg, AppSizes.paddingLg,
                    AppSizes.paddingLg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good morning! 👋",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Today's Pills",
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        IconButton.filled(
                          icon: const Icon(Icons.filter_list_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? DarkColors.surfaceVariant
                                : LightColors.surfaceVariant,
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingLg),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: _PlaceholderBody(
                icon: Icons.medication_liquid_rounded,
                title: 'No medicines scheduled',
                subtitle:
                    'Tap the + button to add your first\nmedicine reminder',
                isDark: isDark,
                primaryColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color primaryColor;

  const _PlaceholderBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // Space for floating nav bar
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
