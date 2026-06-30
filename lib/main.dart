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
import 'features/onboarding/onboarding_intro_screen.dart';
import 'features/onboarding/permission_onboarding_screen.dart';

// ── SharedPrefs key for intro completion ──────────────────────────────────────

const _kIntroDone = 'intro_done_v1';

Future<bool> _isIntroDone(SharedPreferences p) async =>
    p.getBool(_kIntroDone) ?? false;

Future<void> _markIntroDone(SharedPreferences p) async =>
    p.setBool(_kIntroDone, true);

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  await alarmService.initialize();
  await notificationService.initialize();

  // Reschedule all active alarms on every startup (covers reboots too).
  try {
    final db = AppDatabase.instance;
    final repo = DoseGroupRepository(db);
    final groups = await repo.getAll(activeOnly: true);
    await alarmService.rescheduleAll(groups);
  } catch (_) {}

  // Capture alarm that fires while app is closed.
  Alarm.ringStream.stream.listen((s) => _pendingAlarmId = s.id);

  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MedRemindApp(),
  ));
}

int? _pendingAlarmId;

// ── App root ──────────────────────────────────────────────────────────────────

class MedRemindApp extends ConsumerStatefulWidget {
  const MedRemindApp({super.key});

  @override
  ConsumerState<MedRemindApp> createState() => _MedRemindAppState();
}

class _MedRemindAppState extends ConsumerState<MedRemindApp> {
  // null = loading, false = show intro, 'perm' = show permissions, true = done
  Object? _flow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPrefsProvider);
      final introDone = await _isIntroDone(prefs);
      final permsDone = await isOnboardingDone();

      if (!mounted) return;
      if (!introDone) {
        setState(() => _flow = false); // show intro
      } else if (!permsDone) {
        setState(() => _flow = 'perm'); // show permissions
      } else {
        setState(() => _flow = true); // main app
        _handlePendingAlarm();
      }
    });
  }

  void _handlePendingAlarm() {
    if (_pendingAlarmId != null) {
      final id = _pendingAlarmId!;
      _pendingAlarmId = null;
      // Resolve group ID from alarm mapping, then navigate
      alarmService.getGroupIdForAlarm(id).then((groupId) {
        if (mounted) {
          appRouter.go(AppRoutes.activeAlarm, extra: {
            'alarmId': id,
            'doseGroupId': groupId ?? '',
            'logId': null,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    Widget home;

    if (_flow == null) {
      // Loading splash
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_flow == false) {
      // Show intro onboarding
      home = OnboardingIntroScreen(
        onDone: () async {
          final prefs = ref.read(sharedPrefsProvider);
          await _markIntroDone(prefs);
          setState(() => _flow = 'perm');
        },
      );
    } else if (_flow == 'perm') {
      // Show permission onboarding
      home = PermissionOnboardingScreen(
        onComplete: () => setState(() {
          _flow = true;
          _handlePendingAlarm();
        }),
      );
    } else {
      // Main app (router handles navigation)
      return MaterialApp.router(
        title: 'MedRemind',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
      );
    }

    return MaterialApp(
      title: 'MedRemind',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: home,
    );
  }
}
