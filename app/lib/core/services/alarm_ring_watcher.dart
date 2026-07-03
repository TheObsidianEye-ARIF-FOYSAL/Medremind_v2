import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_service.dart';
import '../models/dose_log.dart';
import '../repositories/dose_log_repository.dart';
import 'alarm_service.dart';
import 'app_settings_service.dart';
import 'notification_service.dart';

const maxAutoSnoozes = 5;
const ringDuration = Duration(minutes: 1);
const snoozeDuration = Duration(minutes: 5);

/// Owns the ring → auto-snooze → auto-skip cycle centrally (one timer per
/// alarm id, started the moment the OS alarm actually rings), instead of
/// leaving it to the full-screen ActiveAlarmScreen's own Timer. The
/// full-screen screen isn't guaranteed to launch on every device/Android
/// version (OEM full-screen-intent restrictions, locked screen, etc.), so a
/// timer that only lives inside that screen's State would silently never
/// run in those cases. This watcher runs as long as the app process is
/// alive, independent of which screen (if any) is currently shown:
///   • Ring for 1 minute.
///   • If untouched, auto-snooze: re-ring in 5 minutes.
///   • After 5 auto-snoozes, mark the dose as Skipped instead of re-ringing.
///   • A manual user action (from ActiveAlarmScreen or elsewhere) cancels
///     the pending timer via [cancel].
class AlarmRingWatcher {
  final _timers = <int, Timer>{};

  String _snoozeKey(String groupId) {
    final now = DateTime.now();
    return 'snooze_count_${groupId}_${now.year}${now.month}${now.day}';
  }

  /// Call when `Alarm.ringStream` fires for [alarmId] belonging to [groupId].
  void onRing(int alarmId, String groupId) {
    _timers.remove(alarmId)?.cancel();
    _timers[alarmId] = Timer(ringDuration, () => _autoStop(alarmId, groupId));

    // Independent of the ring/snooze/skip cycle: fire an optional silent
    // "Push Notifications" companion if the user has that toggle on.
    _maybeShowPushNotification(alarmId, groupId);
  }

  /// Call when the user explicitly acts on an alarm (Taken/Snooze/Skip) so
  /// the auto-timer doesn't also fire and double-handle it.
  void cancel(int alarmId) {
    _timers.remove(alarmId)?.cancel();
  }

  Future<void> _autoStop(int alarmId, String groupId) async {
    _timers.remove(alarmId);
    await alarmService.cancelAlarm(alarmId);

    if (groupId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _snoozeKey(groupId);
    final count = prefs.getInt(key) ?? 0;

    if (count < maxAutoSnoozes) {
      await prefs.setInt(key, count + 1);
      final snoozeAt = DateTime.now().add(snoozeDuration);
      await alarmService.scheduleAlarm(
        id: alarmId + 800000,
        scheduledAt: snoozeAt,
        title: 'Medicine — Snoozed reminder',
        body: 'Tap to open MedRemind and respond',
        groupId: groupId,
      );
    } else {
      await prefs.remove(key);
      await _markSkipped(groupId);
    }
  }

  Future<void> _markSkipped(String groupId) async {
    final db = AppDatabase.instance;
    final logRepo = DoseLogRepository(db);
    final today = DateTime.now();

    final logs = await logRepo.getForDate(today);
    DoseLog? log;
    try {
      log = logs.firstWhere((l) => l.doseGroupId == groupId);
    } catch (_) {}

    log ??= await logRepo.createPending(
      doseGroupId: groupId,
      scheduledFor: DateTime(today.year, today.month, today.day, today.hour),
    );
    await logRepo.updateStatus(log.id, DoseStatus.skipped,
        actedAt: DateTime.now());
  }

  Future<void> _maybeShowPushNotification(int alarmId, String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings.fromPrefs(prefs);
    if (!settings.notificationEnabled) return;

    await notificationService.showReminder(
      id: alarmId,
      title: 'Time for your medicine',
      body: 'Open MedRemind to mark it as taken.',
    );
  }
}

final alarmRingWatcher = AlarmRingWatcher();
