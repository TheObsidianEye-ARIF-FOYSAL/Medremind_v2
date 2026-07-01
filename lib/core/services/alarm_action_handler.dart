import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/dose_log.dart';
import '../repositories/dose_log_repository.dart';
import 'alarm_service.dart';

/// Applies a Dismiss(Taken)/Snooze/Skip alarm action immediately — including
/// the dose-log database write. Callable both from the main isolate
/// (foreground notification tap) and from the background notification
/// isolate (tap while the app is killed/backgrounded), so the buttons work
/// the same regardless of app state.
///
/// Doesn't cancel the triggering notification itself — each action button
/// is already configured with `cancelNotification: true`, so Android
/// dismisses it natively without needing a round-trip back into our code.
Future<void> applyAlarmAction(
    String actionId, int alarmId, String groupId) async {
  debugPrint('[AlarmAction] $actionId alarmId=$alarmId groupId=$groupId');
  try {
    await alarmService.cancelAlarm(alarmId);

    final db = AppDatabase.instance;
    final logRepo = DoseLogRepository(db);

    if (actionId == 'alarm_taken') {
      await _upsertLog(logRepo, groupId, DoseStatus.taken);
    } else if (actionId == 'alarm_skip') {
      await _upsertLog(logRepo, groupId, DoseStatus.skipped);
    } else if (actionId == 'alarm_snooze') {
      // Snooze: re-ring in 5 min (no dose log update).
      final snoozeAt = DateTime.now().add(const Duration(minutes: 5));
      await alarmService.scheduleAlarm(
        id: alarmId + 800000,
        scheduledAt: snoozeAt,
        title: 'Medicine — Snoozed reminder',
        body: 'Respond from the "Medicine Alarm" notification below',
        groupId: groupId,
      );
    }
    debugPrint('[AlarmAction] $actionId applied successfully');
  } catch (e, st) {
    debugPrint('[AlarmAction] FAILED: $e\n$st');
  }
}

/// Creates or updates today's dose log for [groupId] with [status].
Future<void> _upsertLog(
    DoseLogRepository logRepo, String groupId, DoseStatus status) async {
  if (groupId.isEmpty) return;
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
  await logRepo.updateStatus(log.id, status, actedAt: DateTime.now());
  debugPrint('[AlarmAction] dose log ${log.id} set to $status');
}
