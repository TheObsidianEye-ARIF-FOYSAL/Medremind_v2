enum DoseStatus { pending, taken, missed, skipped, snoozed }

/// One historical log entry for a dose.
class DoseLog {
  final String id;
  final String doseGroupId;
  final DateTime scheduledFor;
  final DoseStatus status;
  final DateTime? actedAt;

  const DoseLog({
    required this.id,
    required this.doseGroupId,
    required this.scheduledFor,
    this.status = DoseStatus.pending,
    this.actedAt,
  });

  DoseLog copyWith({DoseStatus? status, DateTime? actedAt}) => DoseLog(
        id: id,
        doseGroupId: doseGroupId,
        scheduledFor: scheduledFor,
        status: status ?? this.status,
        actedAt: actedAt ?? this.actedAt,
      );
}
