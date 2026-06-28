// TODO Phase 3: implement permission prompts
// Android 13+ POST_NOTIFICATIONS, Android 12+ SCHEDULE_EXACT_ALARM,
// battery optimization exemption, iOS notification permission.
abstract class PermissionService {
  Future<bool> requestNotificationPermission();
  Future<bool> requestExactAlarmPermission();
  Future<void> requestBatteryOptimizationExemption();
  Future<bool> areNotificationsEnabled();
}
