import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationServiceImpl {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> _notificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('notification_enabled') ?? true;
  }

  Future<bool> _alarmsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('alarm_enabled') ?? true;
  }

  /// Show a silent/notification-style reminder (respects notification toggle).
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

  /// Returns true if the alarm (ringing) mode is enabled by the user.
  Future<bool> isAlarmEnabled() => _alarmsEnabled();

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}

final notificationService = NotificationServiceImpl();
