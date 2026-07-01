import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/dose_group_repository.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/generic_group_repository.dart';
import '../repositories/medicine_dataset_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.instance;
  ref.onDispose(db.close);
  return db;
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final repo = MedicineRepository(ref.watch(appDatabaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final doseGroupRepositoryProvider = Provider<DoseGroupRepository>((ref) {
  final repo = DoseGroupRepository(ref.watch(appDatabaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final doseLogRepositoryProvider = Provider<DoseLogRepository>((ref) {
  final repo = DoseLogRepository(ref.watch(appDatabaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final genericGroupRepositoryProvider = Provider<GenericGroupRepository>(
  (_) => GenericGroupRepository(),
);

final medicineDatasetRepositoryProvider = Provider<MedicineDatasetRepository>(
  (_) => medicineDatasetRepository,
);

// ── Reactive stream providers ─────────────────────────────────────────────────

final medicinesStreamProvider = StreamProvider((ref) async* {
  final repo = ref.watch(medicineRepositoryProvider);
  yield await repo.getAll();
  yield* repo.watchAll;
});

final doseGroupsStreamProvider = StreamProvider((ref) async* {
  final repo = ref.watch(doseGroupRepositoryProvider);
  yield await repo.getAll(activeOnly: true);
  yield* repo.watchAll;
});

final todayLogsStreamProvider = StreamProvider((ref) async* {
  final repo = ref.watch(doseLogRepositoryProvider);
  yield await repo.getForDate(DateTime.now());
  yield* repo.watchAll;
});
