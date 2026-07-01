import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/dose_group.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/navigation/app_transitions.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_constants.dart';
import '../screens/add_medication_screen.dart';
import '../screens/medicine_detail_screen.dart';

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

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      onTap: () => Navigator.of(context).push<void>(
        AppPageRoute(page: MedicineDetailScreen(medicine: med)),
      ),
      child: Container(
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
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert_rounded, size: 18),
            ),
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(Icons.edit_rounded, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    const Text('Edit'),
                  ])),
              const PopupMenuDivider(height: 6),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    const Text('Remove',
                        style: TextStyle(color: Colors.redAccent)),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'edit') {
      await Navigator.of(context).push<void>(
        AppPageRoute(
            page: AddMedicationScreen(existing: med), fullscreenDialog: true),
      );
      return;
    }
    if (action != 'delete') return;

    final groups = await ref.read(doseGroupRepositoryProvider).getAll();
    final usedIn = groups
        .where((g) => g.items.any((i) => i.medicineId == med.id))
        .toList();

    if (usedIn.isNotEmpty) {
      if (!context.mounted) return;
      await _showBlockedDialog(context, usedIn);
      return;
    }

    if (!context.mounted) return;
    final confirmed = await _showConfirmDialog(context);
    if (confirmed != true) return;

    try {
      await ref.read(medicineRepositoryProvider).delete(med.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${med.brandName}" removed'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Couldn\'t remove "${med.brandName}" — it\'s still linked to a dose group.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: Colors.redAccent, size: 26),
        ),
        title: const Text('Remove Medicine', textAlign: TextAlign.center),
        content: Text(
          'Remove "${med.brandName}" from your cabinet? This can\'t be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBlockedDialog(BuildContext context, List<DoseGroup> groups) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: Colors.amber, size: 26),
        ),
        title: const Text('Can\'t Remove Medicine', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${med.brandName}" is still used in ${groups.length == 1 ? 'this dose group' : 'these dose groups'}:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(g.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Remove it from the group first, then try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
