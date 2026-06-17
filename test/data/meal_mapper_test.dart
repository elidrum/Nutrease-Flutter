import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/meal_dto.dart';
import 'package:nutrease_flutter/data/dto/meal_food_dto.dart';
import 'package:nutrease_flutter/data/mapper/meal_mapper.dart';
import 'package:nutrease_flutter/domain/model/food.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_food_item.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';

void main() {
  group('Meal → MealDto (write path)', () {
    test('formats date/time and translates the meal type', () {
      final meal = Meal(
        fascicoloId: 3,
        date: DateTime(2026, 6, 12),
        time: '20:15:00',
        type: MealType.snack,
        items: const [],
      );

      final json = meal.toDto().toJson();

      expect(json['Data'], '2026-06-12');
      expect(json['Ora'], '20:15:00');
      expect(json['Tipologia'], 'Merenda'); // DB enum, not "Spuntino"
    });

    test('item payload carries grams plus originals, never *Calc', () {
      const food =
          Food(id: 9, name: 'Miele', unitConversions: {'cucchiaino': 7});
      const item = MealFoodItem(food: food, amount: 2, unit: 'cucchiaino');

      final json = item.toDto().toInsertJson(7);

      expect(json, {
        'IdPasto': 7,
        'IdAlimento': 9,
        'QuantitaGrammi': 14.0,
        'UnitaMisuraOrig': 'cucchiaino',
        'QuantitaOrig': 2.0,
      });
    });
  });

  group('MealDto → Meal (read path)', () {
    test('parses Data/Ora, maps Tipologia and sums trigger totals', () {
      const dto = MealDto(
        idPasto: 7,
        idFascicolo: 3,
        data: '2026-06-12',
        ora: '08:30:00.123456', // time column may read back with micros
        tipologia: 'Colazione',
      );
      final items = [
        MealFoodDto.fromJson(const {
          'IdAlimento': 10,
          'QuantitaGrammi': 125,
          'UnitaMisuraOrig': 'coppetta',
          'QuantitaOrig': 1,
          'LattosioCalc': 4.5,
          'SorbitoloCalc': 0.1,
          'GlutineCalc': 0.0,
          'CalorieCalc': 80.0,
          'alimento': {
            'IdAlimento': 10,
            'Nome': 'Yogurt intero',
            'ConversioniUnitaMisura': {'coppetta': 125},
          },
        }),
        MealFoodDto.fromJson(const {
          'IdAlimento': 11,
          'QuantitaGrammi': 50,
          'UnitaMisuraOrig': 'g',
          'QuantitaOrig': 50,
          'LattosioCalc': 0.0,
          'SorbitoloCalc': 0.0,
          'GlutineCalc': 3.2,
          'CalorieCalc': 135.0,
          'alimento': {'IdAlimento': 11, 'Nome': 'Pane comune'},
        }),
      ];

      final meal = mealFromDto(dto, items);

      expect(meal.id, 7);
      expect(meal.date, DateTime(2026, 6, 12));
      expect(meal.time, '08:30:00');
      expect(meal.type, MealType.breakfast);
      expect(meal.items, hasLength(2));
      expect(meal.items.first.unit, 'coppetta');
      expect(meal.items.first.amountGrams, 125);
      expect(meal.totals!.lactose, 4.5);
      expect(meal.totals!.gluten, 3.2);
      expect(meal.totals!.kcal, 215.0);
    });

    test('derives the unit factor when the embed is missing it', () {
      const dto = MealFoodDto(
        idAlimento: 12,
        quantitaGrammi: 60,
        unitaMisuraOrig: 'fetta',
        quantitaOrig: 2,
      );

      final item = mealFoodItemFromDto(dto);

      // 2 fette = 60 g stored ⇒ factor 30 g/fetta is reconstructed.
      expect(item.amount, 2);
      expect(item.unit, 'fetta');
      expect(item.amountGrams, 60);
    });
  });
}
