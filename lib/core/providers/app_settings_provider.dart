import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_settings_service.dart';
import 'theme_provider.dart' show sharedPrefsProvider;

// ── AppSettings notifier ──────────────────────────────────────────────────────

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(AppSettings.fromPrefs(_prefs));

  Future<void> setAlarmSound(String path) async {
    state = state.copyWith(alarmSoundPath: path);
    await _prefs.setString('alarm_sound_path', path);
  }

  Future<void> setNotificationEnabled(bool v) async {
    state = state.copyWith(notificationEnabled: v);
    await _prefs.setBool('notification_enabled', v);
  }

  Future<void> setAlarmEnabled(bool v) async {
    state = state.copyWith(alarmEnabled: v);
    await _prefs.setBool('alarm_enabled', v);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AppSettingsNotifier(prefs);
});
