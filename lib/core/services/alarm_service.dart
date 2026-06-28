import 'package:alarm/alarm.dart';

/// Wraps the `alarm` package with app-specific logic.
/// All alarm IDs are derived from dose group + scheduled date to be stable.
class AlarmServiceImpl {
  static const _defaultSoundPath = 'assets/audio/alarm.mp3';

  Future<void> initialize() async {
    await Alarm.init();
  }

  /// Schedule a ringing alarm for [scheduledAt].
  /// [id] must be unique per alarm; [groupId] is for logging.
  Future<void> scheduleAlarm({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    // Don't schedule alarms in the past.
    if (scheduledAt.isBefore(DateTime.now())) return;

    final settings = AlarmSettings(
      id: id,
      dateTime: scheduledAt,
      assetAudioPath: _defaultSoundPath,
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      warningNotificationOnKill: true,
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Dismiss',
        icon: 'notification_icon',
      ),
    );
    await Alarm.set(alarmSettings: settings);
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  Future<void> cancelAll() async {
    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      await Alarm.stop(alarm.id);
    }
  }

  Future<List<AlarmSettings>> getActive() => Alarm.getAlarms();

  /// Derive a stable integer ID from a dose group id string + date.
  static int alarmId(String doseGroupId, DateTime date) {
    final key = '${doseGroupId}_${date.year}${date.month}${date.day}';
    return key.hashCode.abs() % 100000;
  }
}

final alarmService = AlarmServiceImpl();
