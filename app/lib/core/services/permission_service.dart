import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionServiceImpl {
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // iOS handled by the alarm package during init
    return true;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    return Permission.notification.isGranted;
  }

  Future<void> requestAll() async {
    await requestNotificationPermission();
    await requestExactAlarmPermission();
    await requestBatteryOptimizationExemption();
  }
}

final permissionService = PermissionServiceImpl();
