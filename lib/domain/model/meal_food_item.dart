import 'food.dart';

/// Una riga di pasto come composta nella UI: un alimento con quantità e unità
/// inserite dall'utente. La conversione in grammi è derivata, mai memorizzata a parte.
class MealFoodItem {
  final Food food;
  final double amount;
  final String unit;

  const MealFoodItem({
    required this.food,
    required this.amount,
    required this.unit,
  });

  /// Grammi inviati al DB come `QuantitaGrammi` (gli originali viaggiano insieme).
  double get amountGrams => food.toGrams(amount, unit);
}
