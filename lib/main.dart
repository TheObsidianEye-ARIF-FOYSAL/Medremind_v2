import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_service.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/repositories/dose_group_repository.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/permission_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  await alarmService.initialize();
  await notificationService.initialize();

  // Reschedule all active dose group alarms on every startup.
  // This covers: fresh installs, app restarts, and device reboots.
  try {
    final db = AppDatabase.instance;
    final repo = DoseGroupRepository(db);
    final groups = await repo.getAll(activeOnly: true);
    await alarmService.rescheduleAll(groups);
  } catch (_) {
    // Non-fatal — alarms reschedule on next interaction
  }

  // Store alarm that fires while app is closed; handle in initState.
  Alarm.ringStream.stream.listen((s) => _pendingAlarmId = s.id);

  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MedRemindApp(),
  ));
}

int? _pendingAlarmId;

class MedRemindApp extends ConsumerStatefulWidget {
  const MedRemindApp({super.key});

  @override
  ConsumerState<MedRemindApp> createState() => _MedRemindAppState();
}

class _MedRemindAppState extends ConsumerState<MedRemindApp> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final done = await isOnboardingDone();
      if (mounted) setState(() => _onboardingDone = done);

      if (_pendingAlarmId != null) {
        appRouter.go(AppRoutes.activeAlarm, extra: {
          'alarmId': _pendingAlarmId!,
          'doseGroupId': '',
        });
        _pendingAlarmId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Show permission onboarding exactly once on fresh install.
    if (_onboardingDone == false) {
      return MaterialApp(
        title: 'MedRemind',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: PermissionOnboardingScreen(
          onComplete: () => setState(() => _onboardingDone = true),
        ),
      );
    }

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
