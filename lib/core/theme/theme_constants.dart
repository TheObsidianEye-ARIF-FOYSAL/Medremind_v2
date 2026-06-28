import 'package:flutter/material.dart';

/// The three built-in color palettes. Each works in both light and dark mode,
/// giving 3 × 2 = 6 total theme combinations selectable from Settings.
enum AppColorPalette {
  purple('Purple', Color(0xFF6C5CE7), Color(0xFF9B8EF7)),
  teal('Teal', Color(0xFF00B4D8), Color(0xFF48CAE4)),
  rose('Rose', Color(0xFFE91E8C), Color(0xFFF06292));

  const AppColorPalette(this.label, this.primary, this.primaryLight);
  final String label;
  final Color primary;
  final Color primaryLight;
}

/// Shared dark-mode surface/background tokens.
class DarkColors {
  static const background = Color(0xFF0E0E10);
  static const surface = Color(0xFF1C1C26);
  static const surfaceVariant = Color(0xFF252535);
  static const surfaceHigh = Color(0xFF2E2E42);
  static const outline = Color(0xFF3A3A4A);
  static const outlineVariant = Color(0xFF282838);
  static const onBackground = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFFE8E8F0);
  static const onSurfaceMuted = Color(0xFF8888A8);
}

/// Shared light-mode surface/background tokens.
class LightColors {
  static const background = Color(0xFFF4F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEEEF8);
  static const surfaceHigh = Color(0xFFE8E8F4);
  static const outline = Color(0xFFD0D0E0);
  static const outlineVariant = Color(0xFFEAEAF2);
  static const onBackground = Color(0xFF1A1A2E);
  static const onSurface = Color(0xFF2D2D3F);
  static const onSurfaceMuted = Color(0xFF6B6B88);
}

/// Semantic / tag colours — identical in both modes.
class TagColors {
  static const morning = Color(0xFF00C896);       // green
  static const afternoon = Color(0xFFFF8C42);     // orange
  static const evening = Color(0xFF9B59B6);       // purple
  static const night = Color(0xFF4A90D9);         // blue

  static const taken = Color(0xFF00C896);
  static const missed = Color(0xFFE53E3E);
  static const snoozed = Color(0xFFF6AD55);
  static const skipped = Color(0xFF718096);
  static const pending = Color(0xFF8888A8);
}

/// Layout / sizing constants.
class AppSizes {
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radiusCard = 24.0;
  static const radiusPill = 100.0;

  static const paddingXs = 4.0;
  static const paddingSm = 8.0;
  static const paddingMd = 16.0;
  static const paddingLg = 24.0;
  static const paddingXl = 32.0;

  static const navBarHeight = 64.0;
  static const navBarRadius = 32.0;
  static const navBarPaddingH = 16.0;
  static const navBarPaddingB = 12.0;

  static const cardElevation = 0.0;
}
