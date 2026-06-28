import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_constants.dart';
import 'app_router.dart';

class _NavTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _tabs = [
  _NavTab(
    path: AppRoutes.home,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _NavTab(
    path: AppRoutes.calendar,
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: 'Calendar',
  ),
  _NavTab(
    path: AppRoutes.medicines,
    icon: Icons.medication_outlined,
    activeIcon: Icons.medication_rounded,
    label: 'Medicines',
  ),
  _NavTab(
    path: AppRoutes.finder,
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label: 'Finder',
  ),
  _NavTab(
    path: AppRoutes.settings,
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: selected,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.navBarPaddingH,
          0,
          AppSizes.navBarPaddingH,
          AppSizes.navBarPaddingB,
        ),
        child: Container(
          height: AppSizes.navBarHeight,
          decoration: BoxDecoration(
            color: isDark ? DarkColors.surfaceHigh : LightColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.navBarRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _tabs.length,
              (i) => _NavItem(
                tab: _tabs[i],
                isSelected: selectedIndex == i,
                primaryColor: theme.colorScheme.primary,
                isDark: isDark,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: AppSizes.navBarHeight,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: isSelected ? 48 : 40,
            height: isSelected ? 48 : 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 24,
              color: isSelected
                  ? primaryColor
                  : (isDark
                      ? DarkColors.onSurfaceMuted
                      : LightColors.onSurfaceMuted),
            ),
          ),
        ),
      ),
    );
  }
}
