/// Quantità di nutrienti aggregate in grammi (kcal per l'energia).
///
/// Calcolate dal trigger DB `calcola_nutrienti_pasto` (ADR-0010): il client si
/// limita a leggerle e sommarle, non le calcola mai dal dataset.
class NutrientTotals {
  final double lactose;
  final double sorbitol;
  final double gluten;
  final double kcal;

  const NutrientTotals({
    this.lactose = 0,
    this.sorbitol = 0,
    this.gluten = 0,
    this.kcal = 0,
  });

  static const NutrientTotals zero = NutrientTotals();

  NutrientTotals operator +(NutrientTotals other) => NutrientTotals(
        lactose: lactose + other.lactose,
        sorbitol: sorbitol + other.sorbitol,
        gluten: gluten + other.gluten,
        kcal: kcal + other.kcal,
      );
}
