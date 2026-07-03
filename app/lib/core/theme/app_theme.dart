import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_constants.dart';

class AppTheme {
  AppTheme._();

  /// Builds a [ThemeData] for the given [palette] and [brightness].
  /// Call this from the MaterialApp builder to swap between the 6 theme combos.
  static ThemeData build({
    required AppColorPalette palette,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = palette.primary;

    // Generate Material 3 ColorScheme from seed, then override surfaces.
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? primary.withValues(alpha: 0.25)
          : primary.withValues(alpha: 0.12),
      surface: isDark ? DarkColors.surface : LightColors.surface,
      surfaceContainerHighest:
          isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
      surfaceContainerHigh:
          isDark ? DarkColors.surfaceHigh : LightColors.surfaceHigh,
      onSurface: isDark ? DarkColors.onSurface : LightColors.onSurface,
      onSurfaceVariant:
          isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted,
      outline: isDark ? DarkColors.outline : LightColors.outline,
      outlineVariant:
          isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
    );

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(
          fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
      displayMedium: GoogleFonts.inter(
          fontSize: 45, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleSmall: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isDark ? DarkColors.background : LightColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? DarkColors.background : LightColors.background,
        foregroundColor: isDark ? DarkColors.onBackground : LightColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? DarkColors.onBackground : LightColors.onBackground,
        ),
        iconTheme: IconThemeData(
          color: isDark ? DarkColors.onSurface : LightColors.onSurface,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: isDark ? DarkColors.surface : LightColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button (used for pill-shaped CTAs)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(
            color: isDark ? DarkColors.outline : LightColors.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted,
          fontSize: 14,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? DarkColors.outlineVariant : LightColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: IconThemeData(
        color: isDark ? DarkColors.onSurface : LightColors.onSurface,
        size: 24,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? DarkColors.surfaceHigh : LightColors.onBackground,
        contentTextStyle: GoogleFonts.inter(
          color: isDark ? DarkColors.onBackground : LightColors.surface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? DarkColors.surface : LightColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusCard),
          ),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? DarkColors.surface : LightColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
      ),
    );
  }
}
