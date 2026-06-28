// TODO Phase 1: implement with Drift (SQLite)
// This file will wire up the local database — medicines, dose groups, logs.
abstract class DatabaseService {
  Future<void> initialize();
  Future<void> close();
}
