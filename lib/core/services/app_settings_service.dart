import 'package:shared_preferences/shared_preferences.dart';

// ── Alarm sound catalog ───────────────────────────────────────────────────────

class AlarmSoundOption {
  final String label;
  final String assetPath;
  const AlarmSoundOption(this.label, this.assetPath);
}

const alarmSoundOptions = [
  AlarmSoundOption('Digital Clock',
      'assets/audio/universfield-digital-alarm-clock-151920.mp3'),
  AlarmSoundOption('Digital Alarm II',
      'assets/audio/universfield-digital-alarm-02-151919.mp3'),
  AlarmSoundOption(
      'Alarm Clock', 'assets/audio/freesound_community-alarm-clock-90867.mp3'),
  AlarmSoundOption('Generic Alarm',
      'assets/audio/freesound_community-generic-alarm-clock-86759.mp3'),
  AlarmSoundOption('Simple Alarm',
      'assets/audio/lesiakower-oversimplified-alarm-clock-113180.mp3'),
  AlarmSoundOption(
      'Classic Ring', 'assets/audio/8footdino_on_scratch-alarm-301729.mp3'),
  AlarmSoundOption('EAS Alert',
      'assets/audio/jeremayjimenez-kuwait-eas-alarm-1890-367438.mp3'),
  AlarmSoundOption(
      'Bell Alarm', 'assets/audio/u_inx5oo5fv3-alarm-327234.mp3'),
];

// ── Keys ─────────────────────────────────────────────────────────────────────

const _kAlarmSound = 'alarm_sound_path';
const _kNotificationEnabled = 'notification_enabled';
const _kAlarmEnabled = 'alarm_enabled';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppSettings {
  final String alarmSoundPath;
  final bool notificationEnabled;
  final bool alarmEnabled;

  static const defaultSoundPath =
      'assets/audio/universfield-digital-alarm-clock-151920.mp3';

  const AppSettings({
    this.alarmSoundPath = defaultSoundPath,
    this.notificationEnabled = true,
    this.alarmEnabled = true,
  });

  AppSettings copyWith({
    String? alarmSoundPath,
    bool? notificationEnabled,
    bool? alarmEnabled,
  }) =>
      AppSettings(
        alarmSoundPath: alarmSoundPath ?? this.alarmSoundPath,
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      );

  /// Human-readable label for the current alarm sound.
  String get alarmSoundLabel => alarmSoundOptions
      .firstWhere(
        (o) => o.assetPath == alarmSoundPath,
        orElse: () => alarmSoundOptions.first,
      )
      .label;

  static AppSettings fromPrefs(SharedPreferences p) => AppSettings(
        alarmSoundPath: p.getString(_kAlarmSound) ?? defaultSoundPath,
        notificationEnabled: p.getBool(_kNotificationEnabled) ?? true,
        alarmEnabled: p.getBool(_kAlarmEnabled) ?? true,
      );

  Future<void> saveAll(SharedPreferences p) async {
    await p.setString(_kAlarmSound, alarmSoundPath);
    await p.setBool(_kNotificationEnabled, notificationEnabled);
    await p.setBool(_kAlarmEnabled, alarmEnabled);
  }
}
