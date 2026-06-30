import 'package:alarm/alarm.dart';
import '../models/dose_group.dart';

/// Wraps the `alarm` package with app-specific logic.
/// All alarm IDs are derived from dose group + scheduled date to be stable.
class AlarmServiceImpl {
  static const _defaultSoundPath =
      'assets/audio/universfield-digital-alarm-clock-151920.mp3';

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

  /// Convenience: schedule the next occurrence of a dose group alarm.
  /// Called when a group is created/updated, and on app startup.
  Future<void> scheduleForGroup(DoseGroup group) async {
    if (!group.isActive) return;
    final parts = group.timeOfDay.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, h, m);
    // If the time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now.add(const Duration(seconds: 30)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await scheduleAlarm(
      id: alarmId(group.id, scheduled),
      scheduledAt: scheduled,
      title: '${group.label} — Time to take your medicine',
      body: group.items.length == 1
          ? 'Take your medicine now'
          : 'Take ${group.items.length} medicines now',
    );
  }

  /// Reschedule all active groups. Call on app startup.
  Future<void> rescheduleAll(List<DoseGroup> groups) async {
    for (final g in groups) {
      await scheduleForGroup(g);
    }
  }

  /// Derive a stable integer ID from a dose group id string + date.
  static int alarmId(String doseGroupId, DateTime date) {
    final key = '${doseGroupId}_${date.year}${date.month}${date.day}';
    return key.hashCode.abs() % 100000;
  }
}

final alarmService = AlarmServiceImpl();
