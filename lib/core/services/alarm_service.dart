// TODO Phase 3: implement with the `alarm` package
// Schedules, cancels, and reschedules ringing alarms for DoseGroups.
abstract class AlarmService {
  Future<void> scheduleAlarm({
    required int id,
    required DateTime scheduledAt,
    required String label,
  });

  Future<void> cancelAlarm(int id);

  Future<void> rescheduleAll();
}
