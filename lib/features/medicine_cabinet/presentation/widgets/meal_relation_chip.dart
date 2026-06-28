import 'package:flutter/material.dart';
import '../../../../core/models/dose_group.dart';
import '../../../../core/common/widgets/pill_button.dart';

class MealRelationPicker extends StatelessWidget {
  final MealRelation selected;
  final ValueChanged<MealRelation> onChanged;

  const MealRelationPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PillChip(
          label: 'Before meals',
          icon: const Icon(Icons.arrow_back_rounded),
          selected: selected == MealRelation.beforeMeal,
          onTap: () => onChanged(MealRelation.beforeMeal),
        ),
        const SizedBox(width: 8),
        PillChip(
          label: 'After meals',
          icon: const Icon(Icons.arrow_forward_rounded),
          selected: selected == MealRelation.afterMeal,
          onTap: () => onChanged(MealRelation.afterMeal),
        ),
        const SizedBox(width: 8),
        PillChip(
          label: 'Anytime',
          selected: selected == MealRelation.none,
          onTap: () => onChanged(MealRelation.none),
        ),
      ],
    );
  }
}
