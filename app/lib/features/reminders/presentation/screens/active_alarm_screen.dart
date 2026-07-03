import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/dose_log.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_ring_watcher.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';

/// Full-screen alarm screen shown when a dose alarm fires.
///
/// The actual ring → auto-snooze → auto-skip timing is owned centrally by
/// [AlarmRingWatcher] (started in main.dart when the alarm rings), since
/// this screen isn't guaranteed to be shown on every device (full-screen
/// intent can be blocked by the OS/OEM). This screen only reflects that
/// state visually and offers manual actions:
///   • Alarm rings for 60 s; if no action → auto-snooze 5 min.
///   • After 5 auto-snoozes → auto-skip (no more re-rings).
///   • "Dismiss — Taken" button (or swipe-up) → marks dose as TAKEN.
///   • "Snooze 5 min" button → stops alarm, re-rings in 5 min.
///   • "Skip" button → marks dose as SKIPPED, no re-ring.
class ActiveAlarmScreen extends ConsumerStatefulWidget {
  final int alarmId;
  final String doseGroupId;

  const ActiveAlarmScreen({
    super.key,
    required this.alarmId,
    required this.doseGroupId,
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

  Timer? _stopTimer;
  bool _ringing = true;
  bool _acted = false;

  // Swipe drag state
  double _dragOffset = 0;
  static const _swipeThreshold = 80.0;

  // Snooze counter SharedPrefs key scoped to group + today's date.
  String get _snoozeKey {
    final now = DateTime.now();
    return 'snooze_count_${widget.doseGroupId}_${now.year}${now.month}${now.day}';
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WakelockPlus.enable();

    _loadGroup();

    // Cosmetic only — switches the icon/text from "ringing" to "stopped"
    // after 60s. The actual auto-snooze/auto-skip decision is made by
    // AlarmRingWatcher centrally (started when the alarm rang), so it
    // still happens correctly even if this screen is closed early.
    _stopTimer = Timer(ringDuration, () {
      if (mounted) setState(() => _ringing = false);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stopTimer?.cancel();
    WakelockPlus.disable();
    // Deliberately does NOT cancel the alarm here when the user didn't act —
    // AlarmRingWatcher owns the ring/auto-snooze/auto-skip cycle and should
    // keep running in the background even if this screen is dismissed
    // without an explicit action.
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

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

  // ── Log helpers ───────────────────────────────────────────────────────────

  /// Finds or creates today's log for this dose group, then updates its status.
  Future<void> _updateLog(DoseStatus status) async {
    if (widget.doseGroupId.isEmpty) return;
    final logRepo = ref.read(doseLogRepositoryProvider);
    final today = DateTime.now();

    final logs = await logRepo.getForDate(today);
    DoseLog? log;
    try {
      log = logs.firstWhere((l) => l.doseGroupId == widget.doseGroupId);
    } catch (_) {
      // No log yet for today — create a pending one first.
      if (status != DoseStatus.snoozed) {
        final scheduledHour = int.tryParse(
                widget.doseGroupId.isNotEmpty
                    ? (_group?.timeOfDay.split(':').first ?? '0')
                    : '0') ??
            0;
        final scheduledMin = int.tryParse(
                widget.doseGroupId.isNotEmpty
                    ? (_group?.timeOfDay.split(':').last ?? '0')
                    : '0') ??
            0;
        final scheduledFor = DateTime(
            today.year, today.month, today.day, scheduledHour, scheduledMin);
        log = await logRepo.createPending(
          doseGroupId: widget.doseGroupId,
          scheduledFor: scheduledFor,
        );
      }
    }

    if (log != null && status != DoseStatus.snoozed) {
      await logRepo.updateStatus(log.id, status, actedAt: DateTime.now());
    }
  }

  // ── Snooze helper (used for manual "Snooze" action) ─────────────────────────

  Future<void> _scheduleSnooze(int originalAlarmId) async {
    if (widget.doseGroupId.isEmpty) return;
    final snoozeAt = DateTime.now().add(snoozeDuration);
    await alarmService.scheduleAlarm(
      id: originalAlarmId + 800000,
      scheduledAt: snoozeAt,
      title: '${_group?.label ?? 'Medicine'} — Snoozed reminder',
      body: 'Tap to open MedRemind and respond',
      groupId: widget.doseGroupId,
    );
  }

  // ── User actions ──────────────────────────────────────────────────────────

  Future<void> _act(DoseStatus status) async {
    if (_acted) return;
    _acted = true;
    _stopTimer?.cancel();
    // Prevent AlarmRingWatcher's own timer from also auto-handling this
    // alarm now that the user has explicitly acted on it.
    alarmRingWatcher.cancel(widget.alarmId);

    await alarmService.cancelAlarm(widget.alarmId);
    // Also cancel any pending snooze alarm.
    await alarmService.cancelAlarm(widget.alarmId + 800000);

    // Reset snooze counter on explicit user action.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snoozeKey);

    if (status == DoseStatus.snoozed) {
      // Manual snooze: re-schedule in 5 min, don't update dose log status.
      await _scheduleSnooze(widget.alarmId);
    } else {
      await _updateLog(status);
    }

    // FIX: alarm was opened via appRouter.go() which replaces the stack,
    // so Navigator.pop() has nothing to return to → black screen.
    // Use appRouter.go() to rebuild the navigation stack at home.
    if (mounted) appRouter.go(AppRoutes.home);
  }

  // ── Swipe gesture ─────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
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

                // ── Pulsing icon ─────────────────────────────────────────
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
                      color: primary.withValues(alpha: _ringing ? 1.0 : 0.5),
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
                      'Will re-ring in 5 min if no action taken',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: AppSizes.paddingMd),

                if (_group != null) ...[
                  Text(
                    _group!.label,
                    style: theme.textTheme.titleLarge?.copyWith(color: primary),
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

                // ── Swipe-up hint ────────────────────────────────────────
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

                // ── Dismiss (= Taken) ────────────────────────────────────
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
