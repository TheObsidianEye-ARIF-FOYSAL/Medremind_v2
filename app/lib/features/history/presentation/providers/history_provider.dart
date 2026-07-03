import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/providers/repository_providers.dart';

// ── Viewed month (default: current month) ────────────────────────────────────

class HistoryState {
  final DateTime viewedMonth;
  const HistoryState({required this.viewedMonth});
  HistoryState copyWith({DateTime? viewedMonth}) =>
      HistoryState(viewedMonth: viewedMonth ?? this.viewedMonth);
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier()
      : super(HistoryState(
          viewedMonth:
              DateTime(DateTime.now().year, DateTime.now().month, 1),
        ));

  void prevMonth() {
    final m = state.viewedMonth;
    state = state.copyWith(viewedMonth: DateTime(m.year, m.month - 1, 1));
  }

  void nextMonth() {
    final m = state.viewedMonth;
    state = state.copyWith(viewedMonth: DateTime(m.year, m.month + 1, 1));
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (_) => HistoryNotifier(),
);

// ── Logs for the viewed month ─────────────────────────────────────────────────

final historyLogsProvider =
    FutureProvider.family<List<DoseLog>, DateTime>((ref, month) async {
  final repo = ref.watch(doseLogRepositoryProvider);
  final start = month;
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return repo.getRange(start, end);
});

// ── Aggregated per-day stats ──────────────────────────────────────────────────

class DayAdherence {
  final DateTime date;
  final int taken;
  final int total;

  const DayAdherence(
      {required this.date, required this.taken, required this.total});

  double get rate => total == 0 ? 0 : taken / total;
}

final historyAdherenceProvider =
    Provider.family<List<DayAdherence>, List<DoseLog>>((ref, logs) {
  final byDay = <DateTime, List<DoseLog>>{};
  for (final log in logs) {
    final d = DateTime(log.scheduledFor.year, log.scheduledFor.month,
        log.scheduledFor.day);
    byDay.putIfAbsent(d, () => []).add(log);
  }
  return byDay.entries
      .map((e) => DayAdherence(
            date: e.key,
            taken: e.value
                .where((l) => l.status == DoseStatus.taken)
                .length,
            total: e.value.length,
          ))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ── Week-level summary ────────────────────────────────────────────────────────

class WeekSummary {
  final int taken;
  final int missed;
  final int skipped;
  final int total;

  const WeekSummary(
      {required this.taken,
      required this.missed,
      required this.skipped,
      required this.total});

  double get rate => total == 0 ? 0 : taken / total;
}

WeekSummary computeWeekSummary(List<DoseLog> logs) {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekLogs = logs
      .where((l) => l.scheduledFor
          .isAfter(weekStart.subtract(const Duration(days: 1))))
      .toList();

  return WeekSummary(
    taken:
        weekLogs.where((l) => l.status == DoseStatus.taken).length,
    missed:
        weekLogs.where((l) => l.status == DoseStatus.missed).length,
    skipped:
        weekLogs.where((l) => l.status == DoseStatus.skipped).length,
    total: weekLogs.length,
  );
}
