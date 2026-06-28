import 'package:flutter/material.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/theme/theme_constants.dart';

class MedicineTypeSelector extends StatelessWidget {
  final MedicineForm selected;
  final ValueChanged<MedicineForm> onChanged;

  const MedicineTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _types = [
    (form: MedicineForm.tablet, label: 'Tablet', icon: Icons.circle_outlined),
    (form: MedicineForm.pill, label: 'Pill', icon: Icons.medication_rounded),
    (form: MedicineForm.syrup, label: 'Syrup', icon: Icons.local_drink_rounded),
    (form: MedicineForm.syringe, label: 'Syringe', icon: Icons.vaccines_rounded),
    (form: MedicineForm.other, label: 'Other', icon: Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _types.map((t) {
          final isSelected = selected == t.form;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingSm),
            child: GestureDetector(
              onTap: () => onChanged(t.form),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                          ? DarkColors.surfaceVariant
                          : LightColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? DarkColors.outline
                              : LightColors.outline,
                          width: 1,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.icon,
                      size: 28,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
