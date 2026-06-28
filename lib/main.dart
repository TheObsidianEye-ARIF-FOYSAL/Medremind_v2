import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/navigation/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load SharedPreferences for theme persistence
  final prefs = await SharedPreferences.getInstance();

  // Initialize alarm and notification services
  await alarmService.initialize();
  await notificationService.initialize();

  // Listen for alarms firing — navigate to ActiveAlarmScreen.
  // The router needs to be ready first, so we store pending alarms
  // and navigate after the app is running.
  Alarm.ringStream.stream.listen((alarmSettings) {
    _pendingAlarmId = alarmSettings.id;
  });

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MedRemindApp(),
    ),
  );
}

int? _pendingAlarmId;

class MedRemindApp extends ConsumerStatefulWidget {
  const MedRemindApp({super.key});

  @override
  ConsumerState<MedRemindApp> createState() => _MedRemindAppState();
}

class _MedRemindAppState extends ConsumerState<MedRemindApp> {
  @override
  void initState() {
    super.initState();
    // Check for pending alarm after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingAlarmId != null) {
        appRouter.go(
          AppRoutes.activeAlarm,
          extra: {
            'alarmId': _pendingAlarmId!,
            'doseGroupId': '',
          },
        );
        _pendingAlarmId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MedRemind',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
