import 'package:flutter/material.dart';

import '../../../../core/models/medicine.dart';
import '../../../../core/theme/theme_constants.dart';

class MedicinePickerSheet extends StatefulWidget {
  final List<Medicine> medicines;
  const MedicinePickerSheet({super.key, required this.medicines});

  @override
  State<MedicinePickerSheet> createState() => _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<MedicinePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final filtered = widget.medicines
        .where((m) => m.brandName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusCard)),
      ),
      child: Column(children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.outline : LightColors.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLg, AppSizes.paddingMd,
              AppSizes.paddingLg, 0),
          child: Row(children: [
            Expanded(
              child: Text('Select Medicine',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingLg, vertical: AppSizes.paddingSm),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search medicines…',
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No medicines found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLg, AppSizes.paddingSm,
                      AppSizes.paddingLg, 40),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSizes.paddingXs),
                  itemBuilder: (ctx, i) {
                    final m = filtered[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(Icons.medication_rounded,
                            color: primary, size: 20),
                      ),
                      title: Text(m.brandName,
                          style: theme.textTheme.titleSmall),
                      subtitle: m.strength.isNotEmpty ? Text(m.strength) : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkColors.surfaceVariant
                              : LightColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(m.form.name,
                            style: theme.textTheme.labelSmall),
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
