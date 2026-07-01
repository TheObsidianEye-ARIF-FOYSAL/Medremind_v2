import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_action_handler.dart';

// ── Background handler (separate Dart isolate) ────────────────────────────────
// Runs even when the app is fully killed. Applies the action (dose-log
// write, snooze reschedule) immediately, rather than deferring it until the
// user next opens the app — otherwise the buttons look broken when tapped
// from a locked screen / killed app.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  final parts = (response.payload ?? '').split('|');
  if (parts.length < 2) return;

  final alarmId = int.tryParse(parts[0]);
  if (alarmId == null) return;
  final groupId = parts[1];
  final actionId = response.actionId ?? 'tap';

  try {
    await Alarm.init();
  } catch (_) {}

  await applyAlarmAction(actionId, alarmId, groupId);
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationServiceImpl {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Called when an alarm action button is tapped while app is in foreground.
  void Function(String actionId, int alarmId, String groupId)? onAlarmAction;

  Future<void> initialize({
    void Function(String actionId, int alarmId, String groupId)? onAlarmAction,
  }) async {
    this.onAlarmAction = onAlarmAction;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
  }

  void _onForegroundResponse(NotificationResponse response) {
    final parts = (response.payload ?? '').split('|');
    if (parts.length < 2) return;
    final alarmId = int.tryParse(parts[0]) ?? 0;
    final groupId = parts[1];
    final actionId = response.actionId ?? 'tap';
    onAlarmAction?.call(actionId, alarmId, groupId);
  }

  Future<bool> _notificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('notification_enabled') ?? true;
  }

  Future<bool> _alarmsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('alarm_enabled') ?? true;
  }

  /// Silent reminder notification (respects notification toggle).
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!await _notificationsEnabled()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'med_remind_channel',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine schedules',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
      ),
      iOS: DarwinNotificationDetails(presentSound: false),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Show a persistent action notification alongside the ringing alarm.
  /// Provides "Dismiss (Taken)", "Snooze 5 min" and "Skip" action buttons.
  Future<void> showAlarmActions({
    required int alarmId,
    required String groupId,
    required String title,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_actions_channel',
      'Alarm Quick Actions',
      channelDescription:
          'Dismiss, snooze or skip a medicine alarm without opening the app',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          'alarm_taken',
          'Dismiss (Taken)',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'alarm_snooze',
          'Snooze 5 min',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'alarm_skip',
          'Skip',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );
    await _plugin.show(
      alarmId + 500000, // offset avoids collision with other notification IDs
      title,
      'Dismiss = taken · Snooze = ring again in 5 min · Skip = mark skipped',
      const NotificationDetails(android: androidDetails),
      payload: '$alarmId|$groupId',
    );
  }

  Future<void> cancelAlarmActions(int alarmId) =>
      _plugin.cancel(alarmId + 500000);

  Future<bool> isAlarmEnabled() => _alarmsEnabled();
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}

final notificationService = NotificationServiceImpl();
