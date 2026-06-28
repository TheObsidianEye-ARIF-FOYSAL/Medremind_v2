import 'package:flutter/material.dart';
import '../../../../core/theme/theme_constants.dart';

/// Horizontal dot-track stepper matching the design's pill-count selector.
/// Shows a filled handle at the current position plus dot stops.
class DoseStepper extends StatelessWidget {
  final double value;        // current quantity
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const DoseStepper({
    super.key,
    required this.value,
    this.min = 0.5,
    this.max = 5,
    this.step = 0.5,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final stops = <double>[];
    for (double v = min; v <= max; v += step) {
      stops.add(double.parse(v.toStringAsFixed(1)));
    }

    return Row(
      children: [
        // Current value badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
          child: Center(
            child: Text(
              value == value.truncateToDouble()
                  ? value.toInt().toString()
                  : value.toString(),
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Dot track
        Expanded(
          child: Row(
            children: stops.map((stop) {
              final isActive = stop <= value;
              final isCurrent =
                  (stop - value).abs() < step * 0.1;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (stop >= min && stop <= max) onChanged(stop);
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isCurrent ? 12 : (isActive ? 8 : 7),
                      height: isCurrent ? 12 : (isActive ? 8 : 7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? primary.withValues(alpha: isCurrent ? 1 : 0.55)
                            : (isDark
                                ? DarkColors.outline
                                : LightColors.outline),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // + / - buttons
        const SizedBox(width: 8),
        _StepButton(
          icon: Icons.remove,
          onTap: value > min
              ? () => onChanged(
                    double.parse((value - step).toStringAsFixed(1)),
                  )
              : null,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(width: 6),
        _StepButton(
          icon: Icons.add,
          onTap: value < max
              ? () => onChanged(
                    double.parse((value + step).toStringAsFixed(1)),
                  )
              : null,
          isDark: isDark,
          primary: primary,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final Color primary;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null
              ? primary.withValues(alpha: 0.15)
              : (isDark ? DarkColors.outlineVariant : LightColors.outlineVariant),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? primary
              : (isDark ? DarkColors.onSurfaceMuted : LightColors.onSurfaceMuted),
        ),
      ),
    );
  }
}
