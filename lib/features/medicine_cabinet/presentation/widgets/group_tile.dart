import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';

class GroupTile extends ConsumerWidget {
  final DoseGroup group;
  const GroupTile({super.key, required this.group});

  static const _labelColors = {
    'Morning': TagColors.morning,
    'Afternoon': TagColors.afternoon,
    'Evening': TagColors.evening,
    'Night': TagColors.night,
  };

  static const _labelIcons = {
    'Morning': Icons.wb_sunny_rounded,
    'Afternoon': Icons.wb_cloudy_rounded,
    'Evening': Icons.nights_stay_outlined,
    'Night': Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _labelColors[group.label] ?? theme.colorScheme.primary;
    final icon = _labelIcons[group.label] ?? Icons.schedule_rounded;

    final timeStr = _fmtTime(group.timeOfDay);
    final medCount = group.items.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(group.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (!group.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Text('Paused',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                '$timeStr · $medCount ${medCount == 1 ? 'medicine' : 'medicines'}'
                '${group.mealRelation == MealRelation.beforeMeal ? ' · Before meal' : group.mealRelation == MealRelation.afterMeal ? ' · After meal' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 5),
              _DayChips(days: group.daysOfWeek, color: color),
            ],
          ),
        ),
        MedChips(group: group, color: color),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
          onSelected: (v) => _onMenu(context, ref, v),
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    group.isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(group.isActive ? 'Pause' : 'Resume'),
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18,
                      color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Remove'),
                ])),
          ],
        ),
      ]),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(doseGroupRepositoryProvider);
    if (action == 'toggle') {
      await repo.setActive(group.id, active: !group.isActive);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Dose Group'),
          content: Text(
              'Remove "${group.label}" dose group? This will also delete all logs for this group.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove',
                    style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.delete(group.id);
      }
    }
  }

  static String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    final per = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${dh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $per';
  }
}

// ── Day chips ─────────────────────────────────────────────────────────────────

class _DayChips extends StatelessWidget {
  final List<int> days; // 1=Mon … 7=Sun; empty = every day
  final Color color;

  const _DayChips({required this.days, required this.color});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Text(
        'Every day',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      );
    }
    return Row(
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        final active = days.contains(dayNum);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: active ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: active
                    ? color
                    : Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MedChips extends ConsumerWidget {
  final DoseGroup group;
  final Color color;
  const MedChips({super.key, required this.group, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final medsAsync = ref.watch(medicinesStreamProvider);
    final medMap = medsAsync.maybeWhen(
      data: (meds) => {for (final m in meds) m.id: m.brandName},
      orElse: () => <String, String>{},
    );

    final items = group.items;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in items.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                '${medMap[item.medicineId] ?? '—'} ×${_qty(item.quantity)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (items.length > 2)
          Text('+${items.length - 2} more',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}
