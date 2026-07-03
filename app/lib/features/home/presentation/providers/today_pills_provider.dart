import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';

// ── Resolved models (medicine names joined in-memory) ─────────────────────────

class ResolvedDoseItem {
  final String medicineName;
  final MedicineForm form;
  final double quantity;

  const ResolvedDoseItem({
    required this.medicineName,
    required this.form,
    required this.quantity,
  });
}

class ResolvedDoseGroup {
  final DoseGroup group;
  final List<ResolvedDoseItem> items;
  final DoseLog? log;

  const ResolvedDoseGroup({
    required this.group,
    required this.items,
    this.log,
  });

  DoseStatus get status => log?.status ?? DoseStatus.pending;
  bool get isTaken => status == DoseStatus.taken;
  bool get isPending => status == DoseStatus.pending;
}

// ── Reactive provider that combines 3 streams ─────────────────────────────────

final resolvedDoseGroupsProvider =
    Provider<AsyncValue<List<ResolvedDoseGroup>>>((ref) {
  final groupsAsync = ref.watch(doseGroupsStreamProvider);
  final medsAsync = ref.watch(medicinesStreamProvider);
  final logsAsync = ref.watch(todayLogsStreamProvider);

  // Only resolve when all three streams have data.
  return groupsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (groups) => medsAsync.when(
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
      data: (meds) => logsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
        data: (logs) {
          final medMap = {for (final m in meds) m.id: m};
          final todayWeekday = DateTime.now().weekday; // 1=Mon … 7=Sun

          final resolved = groups
              // Only include groups scheduled for today's weekday
              .where((g) =>
                  g.daysOfWeek.isEmpty ||
                  g.daysOfWeek.contains(todayWeekday))
              .map((g) {
            final items = g.items.map((i) {
              final med = medMap[i.medicineId];
              return ResolvedDoseItem(
                medicineName: med?.brandName ?? 'Unknown',
                form: med?.form ?? MedicineForm.tablet,
                quantity: i.quantity,
              );
            }).toList();

            final log = logs
                .where((l) => l.doseGroupId == g.id)
                .toList()
                .firstOrNull;

            return ResolvedDoseGroup(group: g, items: items, log: log);
          }).toList()
            ..sort((a, b) =>
                a.group.timeOfDay.compareTo(b.group.timeOfDay));
          return AsyncValue.data(resolved);
        },
      ),
    ),
  );
});

// ── Stats for the day ─────────────────────────────────────────────────────────

class DayStats {
  final int total;
  final int taken;
  final int pending;
  final int skipped;

  const DayStats({
    required this.total,
    required this.taken,
    required this.pending,
    required this.skipped,
  });

  double get adherenceRate => total == 0 ? 0 : taken / total;
}

final dayStatsProvider = Provider<DayStats>((ref) {
  final resolved = ref.watch(resolvedDoseGroupsProvider);
  return resolved.when(
    loading: () => const DayStats(total: 0, taken: 0, pending: 0, skipped: 0),
    error: (_, __) =>
        const DayStats(total: 0, taken: 0, pending: 0, skipped: 0),
    data: (groups) {
      int taken = 0, pending = 0, skipped = 0;
      for (final g in groups) {
        switch (g.status) {
          case DoseStatus.taken:
            taken++;
          case DoseStatus.skipped:
          case DoseStatus.missed:
            skipped++;
          default:
            pending++;
        }
      }
      return DayStats(
        total: groups.length,
        taken: taken,
        pending: pending,
        skipped: skipped,
      );
    },
  );
});
