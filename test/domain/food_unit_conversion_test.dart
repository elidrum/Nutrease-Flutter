import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/food.dart';
import 'package:nutrease_flutter/domain/model/meal_food_item.dart';

void main() {
  const olio = Food(
    id: 1,
    name: 'Olio di oliva',
    unitConversions: {'cucchiaio': 15, 'cucchiaino': 5},
  );

  group('Food.toGrams', () {
    test('"g" is the identity (implicit base unit)', () {
      expect(olio.toGrams(120, 'g'), 120);
    });

    test('converts a known unit via its factor', () {
      expect(olio.toGrams(2, 'cucchiaio'), 30); // 2 * 15 = 30 g
      expect(olio.toGrams(3, 'cucchiaino'), 15);
    });

    test('throws on an unknown unit', () {
      expect(() => olio.toGrams(1, 'tazza'), throwsArgumentError);
    });
  });

  group('Food.availableUnits', () {
    test('prepends "g" as the first canonical option', () {
      expect(olio.availableUnits(), ['g', 'cucchiaio', 'cucchiaino']);
    });

    test('is just ["g"] when the dataset has no conversions', () {
      const plain = Food(id: 2, name: 'Acqua');
      expect(plain.availableUnits(), ['g']);
    });
  });

  group('MealFoodItem.amountGrams', () {
    test('derives grams from the original quantity and unit', () {
      const item = MealFoodItem(food: olio, amount: 2, unit: 'cucchiaio');
      expect(item.amountGrams, 30);
    });
  });
}
