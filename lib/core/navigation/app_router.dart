import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/medicine_cabinet/presentation/screens/medicine_list_screen.dart';
import '../../features/medicine_cabinet/presentation/screens/add_medication_screen.dart';
import '../../features/alternative_finder/presentation/screens/find_alternative_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/reminders/presentation/screens/time_picker_screen.dart';
import '../../features/reminders/presentation/screens/reminder_review_screen.dart';
import '../../features/reminders/presentation/screens/active_alarm_screen.dart';
import 'shell_screen.dart';

// ── Route name constants ──────────────────────────────────────────────────────
class AppRoutes {
  static const home = '/home';
  static const calendar = '/calendar';
  static const medicines = '/medicines';
  static const finder = '/finder';
  static const history = '/history';
  static const settings = '/settings';

  // Full-screen routes (no shell)
  static const addMedication = '/add-medication';
  static const timePicker = '/time-picker';
  static const reminderReview = '/reminder-review';
  static const activeAlarm = '/active-alarm';
  static const loginChoice = '/login';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    // ── Shell (bottom nav) ─────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (c, s) => _fade(s, const HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.calendar,
          pageBuilder: (c, s) => _fade(s, const CalendarScreen()),
        ),
        GoRoute(
          path: AppRoutes.medicines,
          pageBuilder: (c, s) => _fade(s, const MedicineListScreen()),
        ),
        GoRoute(
          path: AppRoutes.finder,
          pageBuilder: (c, s) => _fade(s, const FindAlternativeScreen()),
        ),
        GoRoute(
          path: AppRoutes.history,
          pageBuilder: (c, s) => _fade(s, const HistoryScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (c, s) => _fade(s, const SettingsScreen()),
        ),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ─────────────────────────────────
    GoRoute(
      path: AppRoutes.addMedication,
      pageBuilder: (c, s) => MaterialPage(
        key: s.pageKey,
        fullscreenDialog: true,
        child: const AddMedicationScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.timePicker,
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>?;
        final initial = extra?['time'] as TimeOfDay? ?? TimeOfDay.now();
        final label = extra?['label'] as String?;
        return MaterialPage(
          key: s.pageKey,
          child: TimePickerScreen(initial: initial, label: label),
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.reminderReview}/:id',
      pageBuilder: (c, s) => MaterialPage(
        key: s.pageKey,
        child: ReminderReviewScreen(doseGroupId: s.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.activeAlarm,
      pageBuilder: (c, s) {
        final extra = s.extra as Map<String, dynamic>;
        return MaterialPage(
          key: s.pageKey,
          child: ActiveAlarmScreen(
            alarmId: extra['alarmId'] as int,
            doseGroupId: extra['doseGroupId'] as String,
            logId: extra['logId'] as String?,
          ),
        );
      },
    ),
  ],
);

CustomTransitionPage<T> _fade<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 180),
  );
}
