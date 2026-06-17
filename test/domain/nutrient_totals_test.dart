import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';

void main() {
  group('NutrientTotals +', () {
    test('sums each field independently', () {
      const a = NutrientTotals(lactose: 1.5, sorbitol: 2, gluten: 0.5, kcal: 100);
      const b = NutrientTotals(lactose: 0.5, sorbitol: 3, gluten: 1.5, kcal: 250);

      final sum = a + b;

      expect(sum.lactose, 2.0);
      expect(sum.sorbitol, 5.0);
      expect(sum.gluten, 2.0);
      expect(sum.kcal, 350.0);
    });

    test('zero is the additive identity', () {
      const x = NutrientTotals(lactose: 1, sorbitol: 2, gluten: 3, kcal: 4);
      final sum = NutrientTotals.zero + x;
      expect(sum.lactose, 1);
      expect(sum.sorbitol, 2);
      expect(sum.gluten, 3);
      expect(sum.kcal, 4);
    });

    test('folds a list of per-meal totals', () {
      const meals = [
        NutrientTotals(lactose: 1, kcal: 100),
        NutrientTotals(lactose: 2, kcal: 50),
        NutrientTotals(gluten: 4),
      ];
      final total =
          meals.fold(NutrientTotals.zero, (acc, t) => acc + t);
      expect(total.lactose, 3);
      expect(total.gluten, 4);
      expect(total.kcal, 150);
      expect(total.sorbitol, 0);
    });
  });
}
