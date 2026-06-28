import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full-screen ringing alert — shown when an alarm fires.
/// Provides Take / Snooze (10 min) / Skip actions.
class ActiveAlarmScreen extends ConsumerStatefulWidget {
  final int alarmId;
  final String doseGroupId;
  final String? logId;

  const ActiveAlarmScreen({
    super.key,
    required this.alarmId,
    required this.doseGroupId,
    this.logId,
  });

  @override
  ConsumerState<ActiveAlarmScreen> createState() => _ActiveAlarmScreenState();
}

class _ActiveAlarmScreenState extends ConsumerState<ActiveAlarmScreen>
    with SingleTickerProviderStateMixin {
  DoseGroup? _group;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadGroup();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final repo = ref.read(doseGroupRepositoryProvider);
    final g = await repo.getById(widget.doseGroupId);
    if (mounted) setState(() => _group = g);
  }

  Future<void> _act(DoseStatus status) async {
    // Stop alarm
    await alarmService.cancelAlarm(widget.alarmId);

    // Update dose log if we have a log id
    if (widget.logId != null) {
      final logRepo = ref.read(doseLogRepositoryProvider);
      await logRepo.updateStatus(widget.logId!, status, actedAt: DateTime.now());
    }

    // Snooze: schedule a new alarm in 10 minutes
    if (status == DoseStatus.snoozed) {
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
      await alarmService.scheduleAlarm(
        id: widget.alarmId + 1,
        scheduledAt: snoozeTime,
        title: '⏰ Snoozed reminder',
        body: _group?.label ?? 'Medicine reminder',
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            children: [
              const Spacer(),

              // ── Pulsing icon ─────────────────────────────────────────────
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.15),
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: Icon(
                    Icons.medication_liquid_rounded,
                    size: 64,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Time to take your medicine!',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.paddingMd),

              if (_group != null) ...[
                Text(
                  _group!.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mealText(_group!.mealRelation),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLg),

                // Items list
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  decoration: BoxDecoration(
                    color: isDark ? DarkColors.surface : LightColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  child: Column(
                    children: _group!.items
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.medication_rounded,
                                      size: 20, color: primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.medicineId, // Phase 4: resolve name
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    '× ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(color: primary),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],

              const Spacer(),

              // ── Action buttons ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _act(DoseStatus.taken),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Take'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TagColors.taken,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _act(DoseStatus.snoozed),
                      icon: const Icon(Icons.snooze_rounded),
                      label: const Text('Snooze 10m'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _act(DoseStatus.skipped),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TagColors.missed,
                        side: const BorderSide(color: TagColors.missed),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingMd),
            ],
          ),
        ),
      ),
    );
  }

  String _mealText(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => 'Take before meals',
        MealRelation.afterMeal => 'Take after meals',
        MealRelation.none => '',
      };
}
