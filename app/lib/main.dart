import 'package:alarm/alarm.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_service.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/repositories/dose_group_repository.dart';
import 'core/services/alarm_ring_watcher.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/mobile_web_detector.dart';
import 'features/auth/providers/user_auth_provider.dart';
import 'features/auth/screens/welcome_landing_screen.dart';
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

  // Capture the ringing alarm id so the app can navigate to the full-screen
  // ActiveAlarmScreen (Dismiss/Snooze/Skip). Also start the centralized
  // ring→auto-snooze→auto-skip cycle, which runs independently of whether
  // the full-screen screen actually launches.
  Alarm.ringStream.stream.listen((s) {
    alarmService.getGroupIdForAlarm(s.id).then((groupId) {
      alarmRingWatcher.onRing(s.id, groupId ?? '');
      // If the app's main flow is already resolved (app open/resumed), go
      // straight to the alarm screen. Otherwise stash the id so
      // _handlePendingAlarm can open it once flow resolution finishes
      // (cold start / launched-from-notification case).
      if (_appReady) {
        appRouter.go(AppRoutes.activeAlarm, extra: {
          'alarmId': s.id,
          'doseGroupId': groupId ?? '',
        });
      } else {
        _pendingAlarmId = s.id;
      }
    });
  });

  final app = ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const MedRemindApp(),
  );

  // Device Preview lets a client browsing the web build on a desktop/laptop
  // pick a phone frame to view the app in. Skipped for the real mobile app
  // and for the web build when opened (or installed as a PWA) on a phone,
  // where it should just fill the screen like a native app.
  runApp(_devicePreviewEnabled
      ? DevicePreview(enabled: true, builder: (context) => app)
      : app);
}

/// True only for the web build running on a desktop/laptop browser.
final bool _devicePreviewEnabled = kIsWeb && !isMobileWebBrowser();

int? _pendingAlarmId;
bool _appReady = false;

// ── App root ──────────────────────────────────────────────────────────────────

class MedRemindApp extends ConsumerStatefulWidget {
  const MedRemindApp({super.key});

  @override
  ConsumerState<MedRemindApp> createState() => _MedRemindAppState();
}

class _MedRemindAppState extends ConsumerState<MedRemindApp> {
  // null=loading, 'login'=not logged in, 'intro'=onboarding, 'perm'=permissions,
  // true=main app
  Object? _flow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveFlow());
  }

  Future<void> _resolveFlow() async {
    // Wait for a restored FirebaseAuth session (if any) to finish loading its
    // Firestore profile before deciding whether the user is logged in.
    await ref.read(userAuthProvider.notifier).ready;
    if (!mounted) return;

    final user = ref.read(userAuthProvider);
    if (!user.isLoggedIn) {
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
      _appReady = true;
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

    final userAuth = ref.watch(userAuthProvider);

    // Logged out while in main app (e.g. logout from profile) → go to login.
    if (_flow == true && !userAuth.isLoggedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _flow = 'login'));
    }
    // Login/registration confirmed → advance flow.
    if (_flow == 'login' && userAuth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _flow = null); // show loader briefly
        _resolveFlow();
      });
    }

    Widget home;

    if (_flow == null) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_flow == 'login') {
      home = const WelcomeLandingScreen();
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
        locale: _devicePreviewEnabled ? DevicePreview.locale(context) : null,
        builder: _appBuilder,
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
      locale: _devicePreviewEnabled ? DevicePreview.locale(context) : null,
      builder: _appBuilder,
    );
  }
}

/// Chains the responsive layout builder with Device Preview's frame builder
/// on web (native builds skip straight to `_responsiveBuilder`).
Widget _appBuilder(BuildContext context, Widget? child) {
  final responsive = _responsiveBuilder(context, child);
  return _devicePreviewEnabled
      ? DevicePreview.appBuilder(context, responsive)
      : responsive;
}

/// Applied app-wide (both the pre-login and main router `MaterialApp`s) so
/// every screen behaves consistently across devices without needing changes
/// per-screen:
///   • Clamps the system font-scale so large accessibility text settings
///     can't blow up fixed-height cards/rows into overflow.
///   • On tablet-width screens, centers content in a max-width column
///     instead of letting it stretch edge-to-edge awkwardly.
Widget _responsiveBuilder(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final clampedScaler = mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
  final width = mq.size.width;

  Widget content = child ?? const SizedBox.shrink();
  if (width > 840) {
    content = Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 600, child: content),
    );
  }

  return MediaQuery(
    data: mq.copyWith(textScaler: clampedScaler),
    child: content,
  );
}
