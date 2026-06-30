import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full-screen alarm screen shown when a dose alarm fires.
///
/// Behaviour:
///   • Alarm rings for 60 s, then audio stops.
///   • If the user takes no action after the ring stops, a re-ring fires
///     2 minutes later (total 3 min from original ring).
///   • Dismiss (swipe-up or button) → marks dose as TAKEN.
///   • Snooze → stops alarm, re-rings in 5 minutes.
///   • Skip → marks dose as SKIPPED.
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
  Map<String, String> _medNames = {};
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Timers for auto-stop and re-ring
  Timer? _stopTimer;
  int? _reRingId;
  bool _ringing = true;
  bool _acted = false;

  // Swipe drag state
  double _dragOffset = 0;
  static const _swipeThreshold = 80.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadGroup();

    // Auto-stop alarm audio after 60 s
    _stopTimer = Timer(const Duration(minutes: 1), _onAutoStop);

    // Schedule re-ring 3 min from now (1 min ring + 2 min wait) if no action
    _scheduleReRing();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stopTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadGroup() async {
    final groupRepo = ref.read(doseGroupRepositoryProvider);
    final medRepo = ref.read(medicineRepositoryProvider);

    final g = await groupRepo.getById(widget.doseGroupId);
    if (g == null || !mounted) return;

    final meds = await medRepo.getAll();
    final nameMap = {for (final m in meds) m.id: m.brandName};

    setState(() {
      _group = g;
      _medNames = nameMap;
    });
  }

  // ── Alarm timing ──────────────────────────────────────────────────────────

  Future<void> _scheduleReRing() async {
    if (widget.doseGroupId.isEmpty) return;
    _reRingId = await alarmService.scheduleReRing(
      originalId: widget.alarmId,
      groupId: widget.doseGroupId,
      title: '${_group?.label ?? 'Medicine'} — Reminder again',
      body: 'You missed the previous alarm. Time to take your medicine.',
      delay: const Duration(minutes: 3),
    );
  }

  Future<void> _onAutoStop() async {
    // Stop audio but keep the screen showing
    await alarmService.cancelAlarm(widget.alarmId);
    if (mounted) setState(() => _ringing = false);
  }

  // ── User actions ──────────────────────────────────────────────────────────

  Future<void> _act(DoseStatus status) async {
    if (_acted) return;
    _acted = true;
    _stopTimer?.cancel();

    // Cancel re-ring since user acted
    await alarmService.cancelReRing(widget.alarmId);
    if (_reRingId != null) await alarmService.cancelAlarm(_reRingId!);

    // Stop alarm if still ringing
    await alarmService.cancelAlarm(widget.alarmId);

    // Update dose log
    if (widget.logId != null) {
      final logRepo = ref.read(doseLogRepositoryProvider);
      await logRepo.updateStatus(widget.logId!, status,
          actedAt: DateTime.now());
    }

    // Snooze: re-schedule in 5 minutes
    if (status == DoseStatus.snoozed && widget.doseGroupId.isNotEmpty) {
      final snoozeAt = DateTime.now().add(const Duration(minutes: 5));
      await alarmService.scheduleAlarm(
        id: widget.alarmId + 1,
        scheduledAt: snoozeAt,
        title: '${_group?.label ?? 'Medicine'} — Snoozed reminder',
        body: 'Time to take your medicine',
        groupId: widget.doseGroupId,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  // ── Swipe gesture ─────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    // Only track upward swipes (negative dy)
    if (d.delta.dy < 0) {
      setState(() => _dragOffset = (_dragOffset - d.delta.dy).clamp(0, 160));
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragOffset >= _swipeThreshold) {
      _act(DoseStatus.taken);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final swipePct = (_dragOffset / _swipeThreshold).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              children: [
                const Spacer(),

                // ── Pulsing icon ───────────────────────────────────────────
                ScaleTransition(
                  scale: _ringing ? _pulseAnim : AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: primary.withValues(
                            alpha: _ringing ? 1.0 : 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _ringing
                          ? Icons.alarm_rounded
                          : Icons.alarm_off_rounded,
                      size: 64,
                      color:
                          primary.withValues(alpha: _ringing ? 1.0 : 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _ringing
                      ? 'Time to take your medicine!'
                      : 'Alarm stopped',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                if (!_ringing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Re-ring in ~2 min if no action taken',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: AppSizes.paddingMd),

                if (_group != null) ...[
                  Text(
                    _group!.label,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: primary),
                  ),
                  if (_group!.mealRelation != MealRelation.none) ...[
                    const SizedBox(height: 4),
                    Text(
                      _mealText(_group!.mealRelation),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingLg),
                  _MedicineList(
                    group: _group!,
                    medNames: _medNames,
                    primary: primary,
                    isDark: isDark,
                  ),
                ],

                const Spacer(),

                // ── Swipe-up hint ─────────────────────────────────────────
                AnimatedOpacity(
                  opacity: 1 - swipePct,
                  duration: const Duration(milliseconds: 100),
                  child: Column(children: [
                    Icon(Icons.keyboard_arrow_up_rounded,
                        size: 32,
                        color: TagColors.taken.withValues(
                            alpha: 0.6 + 0.4 * swipePct)),
                    Text(
                      'Swipe up to mark as Taken',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),

                // ── Dismiss (= Take) button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _act(DoseStatus.taken),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Dismiss — Taken'),
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

                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _act(DoseStatus.snoozed),
                      icon: const Icon(Icons.snooze_rounded),
                      label: const Text('Snooze 5 min'),
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
                ]),

                const SizedBox(height: AppSizes.paddingMd),
              ],
            ),
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

// ── Medicine list widget ──────────────────────────────────────────────────────

class _MedicineList extends StatelessWidget {
  final DoseGroup group;
  final Map<String, String> medNames;
  final Color primary;
  final bool isDark;

  const _MedicineList({
    required this.group,
    required this.medNames,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        children: group.items.map((item) {
          final name = medNames[item.medicineId] ?? 'Medicine';
          final qty = item.quantity == item.quantity.truncateToDouble()
              ? item.quantity.toInt().toString()
              : item.quantity.toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(Icons.medication_rounded, size: 20, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name, style: theme.textTheme.bodyMedium),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  'x$qty',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: primary, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
