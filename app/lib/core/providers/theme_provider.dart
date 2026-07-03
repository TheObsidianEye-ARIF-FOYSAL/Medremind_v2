import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_constants.dart';
import '../theme/app_theme.dart';

// ── Persistence keys ─────────────────────────────────────────────────────────
const _kPaletteKey = 'theme_palette_index';
const _kModeKey = 'theme_mode_index';

// ── Shared preferences provider (overridden in main.dart) ────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden');
});

// ── Theme settings state ──────────────────────────────────────────────────────
class ThemeSettings {
  final AppColorPalette palette;
  final ThemeMode mode;

  const ThemeSettings({
    this.palette = AppColorPalette.purple,
    this.mode = ThemeMode.system,
  });

  ThemeSettings copyWith({AppColorPalette? palette, ThemeMode? mode}) =>
      ThemeSettings(
        palette: palette ?? this.palette,
        mode: mode ?? this.mode,
      );
}

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final SharedPreferences _prefs;

  ThemeSettingsNotifier(this._prefs) : super(_load(_prefs));

  static ThemeSettings _load(SharedPreferences p) {
    final pi = (p.getInt(_kPaletteKey) ?? 0)
        .clamp(0, AppColorPalette.values.length - 1);
    final mi = (p.getInt(_kModeKey) ?? 0).clamp(0, ThemeMode.values.length - 1);
    return ThemeSettings(
      palette: AppColorPalette.values[pi],
      mode: ThemeMode.values[mi],
    );
  }

  void setPalette(AppColorPalette palette) {
    state = state.copyWith(palette: palette);
    _prefs.setInt(_kPaletteKey, palette.index);
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _prefs.setInt(_kModeKey, mode.index);
  }
}

final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ThemeSettingsNotifier(prefs);
});

// ── Derived: light + dark ThemeData for the active palette ───────────────────
// MaterialApp needs both so it can switch when the system mode changes.

final lightThemeProvider = Provider<ThemeData>((ref) {
  final palette = ref.watch(themeSettingsProvider).palette;
  return AppTheme.build(palette: palette, brightness: Brightness.light);
});

final darkThemeProvider = Provider<ThemeData>((ref) {
  final palette = ref.watch(themeSettingsProvider).palette;
  return AppTheme.build(palette: palette, brightness: Brightness.dark);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeSettingsProvider).mode;
});
