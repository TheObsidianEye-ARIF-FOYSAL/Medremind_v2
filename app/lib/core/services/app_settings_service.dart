import 'package:shared_preferences/shared_preferences.dart';

// ── Alarm sound catalog ───────────────────────────────────────────────────────

class AlarmSoundOption {
  final String label;
  final String assetPath;
  const AlarmSoundOption(this.label, this.assetPath);
}

const alarmSoundOptions = [
  // ── Classic alarm sounds ──────────────────────────────────────────────────
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
  // ── Melodic / bell sounds ─────────────────────────────────────────────────
  AlarmSoundOption('3D Bells', 'assets/audio/3d_bells.mp3'),
  AlarmSoundOption('Acoustic Melody', 'assets/audio/acoustic_melody.mp3'),
  AlarmSoundOption('Beautiful Bells', 'assets/audio/beautiful_bells.mp3'),
  AlarmSoundOption('Beautiful Ringtone', 'assets/audio/beautiful_ringtone.mp3'),
  AlarmSoundOption('Cute Bells', 'assets/audio/cute_bells.mp3'),
  AlarmSoundOption('Dream Bells', 'assets/audio/dream_bells.mp3'),
  AlarmSoundOption('I Got Rhythm', 'assets/audio/igotrhythm.mp3'),
  AlarmSoundOption('Lovely Bells', 'assets/audio/lovely_bells.mp3'),
  AlarmSoundOption('Nice Bells', 'assets/audio/nice_bells_alarm.mp3'),
  AlarmSoundOption('Quiet Alarm', 'assets/audio/quite_alarm.mp3'),
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
