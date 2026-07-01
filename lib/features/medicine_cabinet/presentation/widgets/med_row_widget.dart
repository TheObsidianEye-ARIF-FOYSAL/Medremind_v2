import 'package:flutter/material.dart';

import '../../../../core/models/medicine.dart';
import '../../../../core/theme/theme_constants.dart';

// Data model for a medicine slot within a dose group
class MedSlot {
  final Medicine med;
  double quantity;
  MedSlot({required this.med, required this.quantity});
}

class MedRowWidget extends StatelessWidget {
  final MedSlot slot;
  final bool isDark;
  final Color primary;
  final Color labelColor;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const MedRowWidget({
    super.key,
    required this.slot,
    required this.isDark,
    required this.primary,
    required this.labelColor,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border(left: BorderSide(color: labelColor, width: 3)),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(Icons.medication_rounded, color: labelColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.med.brandName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (slot.med.strength.isNotEmpty)
                Text(slot.med.strength,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        // Quantity stepper
        Row(children: [
          QtyButton(
            icon: Icons.remove_rounded,
            onTap: slot.quantity > 0.5
                ? () => onQuantityChanged(slot.quantity - 0.5)
                : null,
            primary: primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _qty(slot.quantity),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          QtyButton(
            icon: Icons.add_rounded,
            onTap: slot.quantity < 10
                ? () => onQuantityChanged(slot.quantity + 0.5)
                : null,
            primary: primary,
          ),
        ]),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
        ),
      ]),
    );
  }

  static String _qty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}

class QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color primary;

  const QtyButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: onTap != null
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 14,
              color: onTap != null
                  ? primary
                  : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}
