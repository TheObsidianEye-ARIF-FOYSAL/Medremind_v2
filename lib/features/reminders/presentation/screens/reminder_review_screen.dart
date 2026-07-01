import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/widgets/pill_button.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/theme_constants.dart';

/// Summary screen shown before the user confirms scheduling a reminder.
/// Displays the dose group details and a "Confirm" action.
class ReminderReviewScreen extends ConsumerWidget {
  final String doseGroupId;

  const ReminderReviewScreen({super.key, required this.doseGroupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DoseGroup?>(
          future: ref.read(doseGroupRepositoryProvider).getById(doseGroupId),
          builder: (context, snap) {
            final group = snap.data;
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text('Reminder',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                if (group != null) ...[
                  // Label chip
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Text(
                      group.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _labelColor(group.label),
                      ),
                    ),
                  ),

                  // Medicine card
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.paddingLg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.paddingMd),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medication_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  group.items.length == 1
                                      ? '${group.items.first.quantity.toInt()} medicine'
                                      : '${group.items.length} medicines',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.label,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.restaurant_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _mealText(group.mealRelation),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _daysText(group.daysOfWeek),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXl),

                  // Time display
                  Text(
                    'Select time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(group.timeOfDay),
                    style: theme.textTheme.displayMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, 0,
                      AppSizes.paddingLg, AppSizes.paddingLg),
                  child: PillButton(
                    label: 'Confirm Reminder',
                    onPressed: group != null
                        ? () => _confirm(context, group)
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, DoseGroup group) async {
    final parts = group.timeOfDay.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final now = DateTime.now();
    var scheduled =
        DateTime(now.year, now.month, now.day, h, m);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await alarmService.scheduleAlarm(
      id: AlarmServiceImpl.alarmId(group.id, scheduled),
      scheduledAt: scheduled,
      title: '💊 ${group.label} reminder',
      body: '${group.items.length} medicine(s) — ${_mealText(group.mealRelation)}',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Reminder set for ${_formatTime(group.timeOfDay)}')),
      );
      Navigator.of(context).pop();
    }
  }

  static String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '${displayH.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')} $period';
  }

  static String _mealText(MealRelation r) => switch (r) {
        MealRelation.beforeMeal => 'Before Meals',
        MealRelation.afterMeal => 'After Meals',
        MealRelation.none => 'Anytime',
      };

  static Color _labelColor(String label) => switch (label) {
        'Morning' => TagColors.morning,
        'Afternoon' => TagColors.afternoon,
        'Night' => TagColors.night,
        _ => TagColors.evening,
      };

  static String _daysText(List<int> days) {
    if (days.isEmpty) return 'Every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d - 1]).join(' · ');
  }
}
