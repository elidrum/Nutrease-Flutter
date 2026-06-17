/// Una voce di alimento dal dataset `alimento` (valori per 100 g).
///
/// Il grammo è l'unità base implicita: [unitConversions] contiene solo le
/// conversioni non banali (es. `{"cucchiaio": 15}` = grammi per unità) e non ha
/// mai la chiave `"g"`.
class Food {
  final int id;
  final String name;
  final String? category;
  final double lactosePer100g;
  final double sorbitolPer100g;
  final double glutenPer100g;
  final double kcalPer100g;
  final Map<String, double> unitConversions;

  const Food({
    required this.id,
    required this.name,
    this.category,
    this.lactosePer100g = 0,
    this.sorbitolPer100g = 0,
    this.glutenPer100g = 0,
    this.kcalPer100g = 0,
    this.unitConversions = const {},
  });

  static const String unitGrams = 'g';

  /// Unità selezionabili, con `"g"` sempre per prima come unità base canonica
  /// (il dataset la omette).
  List<String> availableUnits() => [unitGrams, ...unitConversions.keys];

  /// Converte [amount] espresso in [unit] in grammi.
  ///
  /// `"g"` è l'identità; ogni altra unità deve esistere in [unitConversions]
  /// (es. 2 "cucchiaio" * 15 = 30 g), altrimenti lancia un [ArgumentError].
  double toGrams(double amount, String unit) {
    if (unit == unitGrams) return amount;
    final factor = unitConversions[unit];
    if (factor == null) throw ArgumentError('Unknown unit: $unit');
    return amount * factor;
  }
}
