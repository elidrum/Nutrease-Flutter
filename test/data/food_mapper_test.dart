import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/food_dto.dart';
import 'package:nutrease_flutter/data/mapper/food_mapper.dart';

void main() {
  group('FoodDto → Food', () {
    test('maps Italian columns to the English domain model', () {
      final dto = FoodDto.fromJson({
        'IdAlimento': 42,
        'Nome': 'Parmigiano Reggiano',
        'Categoria': 'Formaggi',
        'LattosioP100g': 0.05,
        'SorbitoloP100g': 0,
        'GlutineP100g': 0,
        'CaloriePer100g': 392,
        'ConversioniUnitaMisura': {'cucchiaio': 10},
      });

      final food = dto.toDomain();

      expect(food.id, 42);
      expect(food.name, 'Parmigiano Reggiano');
      expect(food.category, 'Formaggi');
      expect(food.lactosePer100g, 0.05);
      expect(food.kcalPer100g, 392);
      expect(food.unitConversions, {'cucchiaio': 10.0});
    });

    test('tolerates a null ConversioniUnitaMisura and null Categoria', () {
      final dto = FoodDto.fromJson({
        'IdAlimento': 1,
        'Nome': 'Acqua',
        'Categoria': null,
        'LattosioP100g': 0,
        'SorbitoloP100g': 0,
        'GlutineP100g': 0,
        'CaloriePer100g': 0,
        'ConversioniUnitaMisura': null,
      });

      final food = dto.toDomain();

      expect(food.category, isNull);
      expect(food.unitConversions, isEmpty);
      expect(food.availableUnits(), ['g']);
    });
  });

  group('parseUnitConversions', () {
    test('handles jsonb values decoded as int or double', () {
      final parsed = parseUnitConversions({
        'cucchiaio': 15, // int
        'fetta': 27.5, // double
        'tazza': '240', // string-encoded numeric
      });

      expect(parsed, {'cucchiaio': 15.0, 'fetta': 27.5, 'tazza': 240.0});
      expect(parsed['cucchiaio'], isA<double>());
    });

    test('drops non-numeric entries instead of crashing', () {
      final parsed = parseUnitConversions({'cucchiaio': 15, 'nota': 'abc'});

      expect(parsed, {'cucchiaio': 15.0});
    });
  });
}
