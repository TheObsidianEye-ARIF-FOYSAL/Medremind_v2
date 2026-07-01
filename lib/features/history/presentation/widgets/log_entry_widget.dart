import 'package:flutter/material.dart';

import '../../../../core/models/dose_log.dart';
import '../../../../core/theme/theme_constants.dart';

class LogEntryWidget extends StatelessWidget {
  final DoseLog log;
  final bool isDark;
  final Color primary;
  final Map<String, String> groupLabels;

  const LogEntryWidget({
    super.key,
    required this.log,
    required this.isDark,
    required this.primary,
    required this.groupLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, icon, label) = switch (log.status) {
      DoseStatus.taken =>
        (TagColors.taken, Icons.check_circle_rounded, 'Taken'),
      DoseStatus.skipped =>
        (TagColors.skipped, Icons.cancel_outlined, 'Skipped'),
      DoseStatus.missed =>
        (TagColors.missed, Icons.error_outline_rounded, 'Missed'),
      DoseStatus.snoozed =>
        (TagColors.snoozed, Icons.snooze_rounded, 'Snoozed'),
      _ => (TagColors.pending, Icons.radio_button_unchecked, 'Pending'),
    };

    final groupLabel = groupLabels[log.doseGroupId] ?? _shortId(log.doseGroupId);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupLabel,
                style: theme.textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _fmt(log.scheduledFor),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: color)),
        ),
      ]),
    );
  }

  static String _shortId(String id) =>
      id.length > 8 ? '(deleted) ${id.substring(0, 8)}' : id;

  static String _fmt(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day} · ${dh.toString().padLeft(2, '0')}:$m $period';
  }
}
