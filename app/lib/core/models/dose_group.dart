import 'dose_item.dart';

enum MealRelation { beforeMeal, afterMeal, none }

/// A scheduled "dose group" — a time of day + set of medicines + meal relation.
class DoseGroup {
  final String id;
  final String label;          // "Morning", "Afternoon", "Night", or custom
  final String timeOfDay;      // "HH:mm"
  final MealRelation mealRelation;
  final List<int> daysOfWeek;  // 1=Mon … 7=Sun, empty = every day
  final DateTime startDate;
  final DateTime? endDate;     // null = ongoing
  final bool isActive;
  final List<DoseItem> items;

  const DoseGroup({
    required this.id,
    required this.label,
    required this.timeOfDay,
    this.mealRelation = MealRelation.none,
    this.daysOfWeek = const [],
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.items = const [],
  });
}
