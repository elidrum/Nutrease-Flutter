import 'meal_food_item.dart';
import 'meal_type.dart';
import 'nutrient_totals.dart';

/// Un pasto del diario (`pasto` + le sue righe `alimento_pasto`).
///
/// [totals] è popolato solo in lettura (somma delle colonne `*Calc` calcolate
/// dal trigger); in scrittura il client non invia mai valori nutrizionali
/// (ADR-0010).
class Meal {
  final int? id;
  final int fascicoloId;
  final DateTime date;

  /// Orario come `HH:mm:ss` (colonna DB `time`).
  final String time;
  final MealType type;
  final List<MealFoodItem> items;
  final NutrientTotals? totals;

  const Meal({
    this.id,
    required this.fascicoloId,
    required this.date,
    required this.time,
    required this.type,
    required this.items,
    this.totals,
  });
}
