import 'package:flutter/material.dart';

/// Smooth slide-up transition for fullscreen dialogs and bottom sheets.
/// Smooth slide-right transition for regular screen pushes.

class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool fullscreenDialog;

  AppPageRoute({
    required this.page,
    this.fullscreenDialog = false,
    super.settings,
  }) : super(
          fullscreenDialog: fullscreenDialog,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            if (fullscreenDialog) {
              // Slide up from bottom for dialogs
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            }

            // Slide right for regular navigation
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Fade transition — use for overlays, settings sub-screens, etc.
class AppFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppFadeRoute({required this.page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
}
