import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/medicine.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';

class MedicineTile extends ConsumerWidget {
  final Medicine med;
  const MedicineTile({super.key, required this.med});

  static const _formIcons = {
    MedicineForm.tablet: Icons.circle_outlined,
    MedicineForm.pill: Icons.medication_rounded,
    MedicineForm.syrup: Icons.local_drink_rounded,
    MedicineForm.syringe: Icons.vaccines_rounded,
    MedicineForm.other: Icons.more_horiz_rounded,
  };

  static const _formColors = {
    MedicineForm.tablet: Color(0xFF6C5CE7),
    MedicineForm.pill: Color(0xFF00B4D8),
    MedicineForm.syrup: Color(0xFF00C896),
    MedicineForm.syringe: Color(0xFFFF7675),
    MedicineForm.other: Color(0xFFA0A0A0),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = _formColors[med.form] ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              _formIcons[med.form] ?? Icons.medication_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.brandName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (med.strength.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    med.strength,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              med.form.name[0].toUpperCase() + med.form.name.substring(1),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: iconColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (_) => [
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
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Medicine'),
          content: Text('Remove "${med.brandName}" from your cabinet?'),
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
        await ref.read(medicineRepositoryProvider).delete(med.id);
      }
    }
  }
}
