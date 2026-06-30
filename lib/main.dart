import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/firebase_auth_provider.dart';
import 'features/auth/screens/login_register_screen.dart';
import 'features/auth/screens/subscription_screen.dart';
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

  await Firebase.initializeApp();

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
  // null=loading, 'sub'=bdapps not subscribed, 'login'=firebase not logged in,
  // 'intro'=onboarding, 'perm'=permissions, true=main app
  Object? _flow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveFlow());
  }

  Future<void> _resolveFlow() async {
    // Allow AuthNotifier._loadSession() micro-task to complete first
    await Future.microtask(() {});
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      setState(() => _flow = 'sub');
      return;
    }

    final firebase = ref.read(firebaseAuthProvider);
    if (!firebase.isLoggedIn) {
      setState(() => _flow = 'login');
      return;
    }

    final prefs = ref.read(sharedPrefsProvider);
    final introDone = await _isIntroDone(prefs);
    final permsDone = await isOnboardingDone();

    if (!mounted) return;
    if (!introDone) {
      setState(() => _flow = 'intro');
    } else if (!permsDone) {
      setState(() => _flow = 'perm');
    } else {
      setState(() => _flow = true);
      _handlePendingAlarm();
    }
  }

  void _handlePendingAlarm() {
    if (_pendingAlarmId != null) {
      final id = _pendingAlarmId!;
      _pendingAlarmId = null;
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

    final auth = ref.watch(authProvider);
    final firebase = ref.watch(firebaseAuthProvider);

    // BdApps session lost → go to subscription screen
    if (_flow == true && !auth.isAuthenticated) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _flow = 'sub'));
    }
    // Firebase logged out while in main app → go to login screen
    if (_flow == true && auth.isAuthenticated && !firebase.isLoggedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _flow = 'login'));
    }
    // BdApps subscription confirmed → re-resolve (will check Firebase next)
    if (_flow == 'sub' && auth.isAuthenticated) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _resolveFlow());
    }
    // Firebase login confirmed → advance flow
    if (_flow == 'login' && firebase.isLoggedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _resolveFlow());
    }

    Widget home;

    if (_flow == null) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_flow == 'sub') {
      home = const SubscriptionScreen();
    } else if (_flow == 'login') {
      home = const LoginRegisterScreen();
    } else if (_flow == 'intro') {
      home = OnboardingIntroScreen(
        onDone: () async {
          final prefs = ref.read(sharedPrefsProvider);
          await _markIntroDone(prefs);
          setState(() => _flow = 'perm');
        },
      );
    } else if (_flow == 'perm') {
      home = PermissionOnboardingScreen(
        onComplete: () => setState(() {
          _flow = true;
          _handlePendingAlarm();
        }),
      );
    } else {
      return MaterialApp.router(
        title: 'MedRemind',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
      );
    }

    // ValueKey forces a brand-new Navigator (clearing any pushed routes)
    // every time _flow changes.
    return MaterialApp(
      key: ValueKey(_flow),
      title: 'MedRemind',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: home,
    );
  }
}
