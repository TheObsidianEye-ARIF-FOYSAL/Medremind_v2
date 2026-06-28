import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart' show MedicineForm;
import '../../../../core/providers/repository_providers.dart';
import '../../../home/presentation/providers/today_pills_provider.dart';

// ── Selected date & viewed month ──────────────────────────────────────────────

class CalendarState {
  final DateTime viewedMonth;  // first day of the currently viewed month
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
          viewedMonth: DateTime(
              DateTime.now().year, DateTime.now().month, 1),
          selectedDate: DateTime.now(),
        ));

  void prevMonth() {
    final m = state.viewedMonth;
    state = state.copyWith(
      viewedMonth: DateTime(m.year, m.month - 1, 1),
    );
  }

  void nextMonth() {
    final m = state.viewedMonth;
    state = state.copyWith(
      viewedMonth: DateTime(m.year, m.month + 1, 1),
    );
  }

  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>(
  (_) => CalendarNotifier(),
);

// ── Logs for the viewed month ─────────────────────────────────────────────────

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
    ..sort((a, b) =>
        a.group.timeOfDay.compareTo(b.group.timeOfDay));
});
