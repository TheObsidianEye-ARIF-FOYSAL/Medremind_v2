// TODO Phase 3: implement with flutter_local_notifications
// Handles non-ringing summary notifications (daily digest, missed dose banner).
abstract class NotificationService {
  Future<void> initialize();
  Future<void> showSummary({required String title, required String body});
  Future<void> cancel(int id);
}
