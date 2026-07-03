import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart' show MedicineForm;
import '../../../../core/providers/repository_providers.dart';
import '../../../home/presentation/providers/today_pills_provider.dart';

// ── Day adherence status ──────────────────────────────────────────────────────

enum CalendarDayStatus {
  none,       // no active groups at all
  scheduled,  // future day (or today before any logs) — has active groups
  taken,      // all doses taken
  partial,    // some taken, some not
  missed,     // doses expected but none/few taken
}

// ── Calendar state ────────────────────────────────────────────────────────────

class CalendarState {
  final DateTime viewedMonth;
  final DateTime selectedDate;

  const CalendarState({
    required this.viewedMonth,
    required this.selectedDate,
  });

  CalendarState copyWith({DateTime? viewedMonth, DateTime? selectedDate}) =>
      CalendarState(
        viewedMonth: viewedMonth ?? this.viewedMonth,
        selectedDate: selectedDate ?? this.selectedDate,
      );
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(CalendarState(
          viewedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
          selectedDate: DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day),
        ));

  void prevMonth() {
    final m = state.viewedMonth;
    final newMonth = DateTime(m.year, m.month - 1, 1);
    state = state.copyWith(
      viewedMonth: newMonth,
      selectedDate: _defaultDateForMonth(newMonth),
    );
  }

  void nextMonth() {
    final m = state.viewedMonth;
    final newMonth = DateTime(m.year, m.month + 1, 1);
    state = state.copyWith(
      viewedMonth: newMonth,
      selectedDate: _defaultDateForMonth(newMonth),
    );
  }

  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);

  void goToToday() {
    final now = DateTime.now();
    state = CalendarState(
      viewedMonth: DateTime(now.year, now.month, 1),
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  // If today is in the given month, select today; otherwise select the 1st.
  DateTime _defaultDateForMonth(DateTime month) {
    final now = DateTime.now();
    if (now.year == month.year && now.month == month.month) {
      return DateTime(now.year, now.month, now.day);
    }
    return month; // first day of the month
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>(
  (_) => CalendarNotifier(),
);

// ── Per-day status for the viewed month ──────────────────────────────────────

final monthDayStatusProvider = FutureProvider.family<
    Map<int, CalendarDayStatus>, DateTime>((ref, month) async {
  final logRepo = ref.watch(doseLogRepositoryProvider);
  final groupRepo = ref.watch(doseGroupRepositoryProvider);

  final start = month;
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  final logs = await logRepo.getRange(start, end);
  final groups = await groupRepo.getAll(activeOnly: true);

  final totalGroups = groups.length;
  if (totalGroups == 0) return {};

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

  // Group logs by day
  final Map<int, List<DoseLog>> logsByDay = {};
  for (final log in logs) {
    final day = log.scheduledFor.day;
    (logsByDay[day] ??= []).add(log);
  }

  final result = <int, CalendarDayStatus>{};

  for (var d = 1; d <= daysInMonth; d++) {
    final date = DateTime(month.year, month.month, d);
    final dayLogs = logsByDay[d] ?? [];

    if (date.isAfter(today)) {
      result[d] = CalendarDayStatus.scheduled;
    } else if (date.isAtSameMomentAs(today)) {
      // Today: check actual log statuses
      if (dayLogs.isEmpty) {
        result[d] = CalendarDayStatus.scheduled;
      } else {
        result[d] = _computeStatus(dayLogs, totalGroups);
      }
    } else {
      // Past day
      if (dayLogs.isEmpty) {
        result[d] = CalendarDayStatus.missed;
      } else {
        result[d] = _computeStatus(dayLogs, totalGroups);
      }
    }
  }

  return result;
});

CalendarDayStatus _computeStatus(List<DoseLog> logs, int totalGroups) {
  final taken = logs.where((l) => l.status == DoseStatus.taken).length;
  final done = logs.where((l) => l.status != DoseStatus.pending).length;
  if (taken == totalGroups) return CalendarDayStatus.taken;
  if (taken > 0) return CalendarDayStatus.partial;
  if (done == totalGroups) return CalendarDayStatus.missed; // all skipped/missed
  return CalendarDayStatus.partial; // some done, some still pending
}

// ── Month adherence summary ───────────────────────────────────────────────────

final monthAdherenceProvider =
    FutureProvider.family<({int taken, int total}), DateTime>(
        (ref, month) async {
  final statusMap =
      await ref.watch(monthDayStatusProvider(month).future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  int taken = 0;
  int total = 0;

  for (final entry in statusMap.entries) {
    final date = DateTime(month.year, month.month, entry.key);
    if (date.isAfter(today)) continue; // don't count future days
    total++;
    if (entry.value == CalendarDayStatus.taken) taken++;
    if (entry.value == CalendarDayStatus.partial) taken++; // partial counts
  }

  return (taken: taken, total: total);
});

// ── Logs for the viewed month (kept for backwards compat) ─────────────────────

final monthLogsProvider =
    FutureProvider.family<List<DoseLog>, DateTime>((ref, month) async {
  final repo = ref.watch(doseLogRepositoryProvider);
  final start = month;
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return repo.getRange(start, end);
});

// ── Resolved groups for a specific date ──────────────────────────────────────

final selectedDateGroupsProvider =
    FutureProvider.family<List<ResolvedDoseGroup>, DateTime>(
        (ref, date) async {
  final groupRepo = ref.watch(doseGroupRepositoryProvider);
  final medRepo = ref.watch(medicineRepositoryProvider);
  final logRepo = ref.watch(doseLogRepositoryProvider);

  final groups = await groupRepo.getAll(activeOnly: true);
  final meds = await medRepo.getAll();
  final logs = await logRepo.getForDate(date);

  final medMap = {for (final m in meds) m.id: m};

  return groups.map((g) {
    final items = g.items.map((i) {
      final med = medMap[i.medicineId];
      return ResolvedDoseItem(
        medicineName: med?.brandName ?? 'Unknown',
        form: med?.form ?? MedicineForm.tablet,
        quantity: i.quantity,
      );
    }).toList();
    final log =
        logs.where((l) => l.doseGroupId == g.id).toList().firstOrNull;
    return ResolvedDoseGroup(group: g, items: items, log: log);
  }).toList()
    ..sort((a, b) => a.group.timeOfDay.compareTo(b.group.timeOfDay));
});
