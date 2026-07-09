import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionServiceImpl {
  Future<bool> requestNotificationPermission() async {
    // permission_handler has no web implementation — OS-level permissions
    // are meaningless in a browser demo anyway, so just report granted.
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // iOS handled by the alarm package during init
    return true;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    return Permission.notification.isGranted;
  }

  Future<void> requestAll() async {
    await requestNotificationPermission();
    await requestExactAlarmPermission();
    await requestBatteryOptimizationExemption();
  }
}

final permissionService = PermissionServiceImpl();
