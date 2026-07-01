import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dose_group.dart';
import 'app_settings_service.dart';

/// Wraps the `alarm` package with app-specific logic.
class AlarmServiceImpl {
  // ── Alarm ID → DoseGroup ID mapping ──────────────────────────────────────

  Future<void> _saveGroupMapping(int alarmId, String groupId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('alarm_group_$alarmId', groupId);
  }

  Future<String?> getGroupIdForAlarm(int alarmId) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('alarm_group_$alarmId');
  }

  Future<void> _clearGroupMapping(int alarmId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('alarm_group_$alarmId');
  }

  // ── Sound from user settings ──────────────────────────────────────────────

  Future<String> _soundPath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('alarm_sound_path') ?? AppSettings.defaultSoundPath;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await Alarm.init();
  }

  Future<bool> _alarmEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('alarm_enabled') ?? true;
  }

  /// Schedule a ringing alarm. Returns false if past or alarm mode disabled.
  Future<bool> scheduleAlarm({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? groupId,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return false;
    if (!await _alarmEnabled()) return false;

    final sound = await _soundPath();

    final settings = AlarmSettings(
      id: id,
      dateTime: scheduledAt,
      assetAudioPath: sound,
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      // No stopButton here on purpose: the `alarm` package's own stop button
      // only silences the ring natively and can't run our Taken/Snooze/Skip
      // logic. Users respond via the full-screen ActiveAlarmScreen instead,
      // which androidFullScreenIntent launches when the alarm rings.
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        icon: 'notification_icon',
      ),
    );
    await Alarm.set(alarmSettings: settings);

    if (groupId != null) {
      await _saveGroupMapping(id, groupId);
    }
    return true;
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
    await _clearGroupMapping(id);
  }

  Future<void> cancelAll() async {
    final alarms = await Alarm.getAlarms();
    for (final a in alarms) {
      await Alarm.stop(a.id);
      await _clearGroupMapping(a.id);
    }
  }

  Future<List<AlarmSettings>> getActive() => Alarm.getAlarms();

  // ── Dose group helpers ────────────────────────────────────────────────────

  /// Schedule the next occurrence of a dose group alarm,
  /// honouring daysOfWeek (empty = every day; 1=Mon … 7=Sun).
  Future<void> scheduleForGroup(DoseGroup group) async {
    if (!group.isActive) return;
    final parts = group.timeOfDay.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final now = DateTime.now();

    // Start with today at the configured time
    var candidate = DateTime(now.year, now.month, now.day, h, m);

    // Advance past "too soon" (within 30 s)
    if (candidate.isBefore(now.add(const Duration(seconds: 30)))) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // If specific days are configured, walk forward until we land on one
    if (group.daysOfWeek.isNotEmpty) {
      for (int i = 0; i < 7; i++) {
        if (group.daysOfWeek.contains(candidate.weekday)) break;
        candidate = candidate.add(const Duration(days: 1));
      }
      // Still not on a valid day? (shouldn't happen with a non-empty list)
      if (!group.daysOfWeek.contains(candidate.weekday)) return;
    }

    await scheduleAlarm(
      id: alarmId(group.id, candidate),
      scheduledAt: candidate,
      title: '${group.label} — Time for your medicine',
      body: 'Tap to open MedRemind and respond',
      groupId: group.id,
    );
  }

  /// Reschedule all active groups. Call on app startup.
  Future<void> rescheduleAll(List<DoseGroup> groups) async {
    for (final g in groups) {
      await scheduleForGroup(g);
    }
  }

  /// Schedule a re-ring alarm [delay] after now if no user action is taken.
  /// Returns the alarm ID of the re-ring alarm, or null if not scheduled.
  Future<int?> scheduleReRing({
    required int originalId,
    required String groupId,
    required String title,
    required String body,
    Duration delay = const Duration(minutes: 3),
  }) async {
    final reRingAt = DateTime.now().add(delay);
    final id = originalId + 900000; // offset to avoid collision
    await scheduleAlarm(
      id: id,
      scheduledAt: reRingAt,
      title: title,
      body: body,
      groupId: groupId,
    );
    return id;
  }

  /// Cancel the re-ring alarm for [originalId].
  Future<void> cancelReRing(int originalId) =>
      cancelAlarm(originalId + 900000);

  /// Derive a stable integer ID from a dose group id string + date.
  static int alarmId(String doseGroupId, DateTime date) {
    final key = '${doseGroupId}_${date.year}${date.month}${date.day}';
    return key.hashCode.abs() % 100000;
  }
}

final alarmService = AlarmServiceImpl();
