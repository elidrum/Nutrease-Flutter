import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/food.dart';
import 'package:nutrease_flutter/domain/model/food_search.dart';

Food food(int id, String name) => Food(id: id, name: name);

void main() {
  group('FoodSearch.search', () {
    test('exact match ranks first, then prefix, then substring', () {
      final all = [
        food(1, 'Pasta al forno'), // prefix
        food(2, 'Insalata di pasta'), // substring
        food(3, 'Pasta'), // exact
      ];

      final results = FoodSearch.search(all, 'pasta');

      expect(results.map((f) => f.id).toList(), [3, 1, 2]);
    });

    test('strips accents consistently on both query and names', () {
      final all = [food(1, 'Però'), food(2, 'Pera')];

      // "però" normalizes to "pero" and must match the accented name exactly.
      final results = FoodSearch.search(all, 'però');

      expect(results.first.id, 1);
      expect(FoodSearch.normalize('Però'), 'pero');
      expect(FoodSearch.normalize('CAFFÈ'), 'caffe');
    });

    test('multiple tokens are combined in AND', () {
      final all = [
        food(1, 'Latte intero'),
        food(2, 'Latte di mandorla'),
        food(3, 'Mandorle tostate'),
      ];

      final results = FoodSearch.search(all, 'latte mandorla');

      expect(results.map((f) => f.id).toList(), [2]);
    });

    test('fuzzy match tolerates a single typo', () {
      final all = [food(1, 'Latte intero'), food(2, 'Pane bianco')];

      // "lattw" is one substitution away from "latte".
      final results = FoodSearch.search(all, 'lattw');

      expect(results.map((f) => f.id).toList(), [1]);
    });

    test('two typos do not match', () {
      final all = [food(1, 'Latte intero')];

      expect(FoodSearch.search(all, 'lwttw'), isEmpty);
    });

    test('ordering is deterministic: ties broken by name', () {
      final all = [
        food(2, 'Mela verde'),
        food(1, 'Mela rossa'),
        food(3, 'Mela gialla'),
      ];

      final results = FoodSearch.search(all, 'mela');

      expect(results.map((f) => f.name).toList(),
          ['Mela gialla', 'Mela rossa', 'Mela verde']);
    });

    test('blank query yields no results', () {
      expect(FoodSearch.search([food(1, 'Pasta')], '   '), isEmpty);
    });

    test('respects the result limit', () {
      final all = [for (var i = 0; i < 80; i++) food(i, 'Pane $i')];

      expect(FoodSearch.search(all, 'pane').length, 50);
      expect(FoodSearch.search(all, 'pane', limit: 10).length, 10);
    });
  });

  group('FoodSearch.levenshtein', () {
    test('computes classic edit distances', () {
      expect(FoodSearch.levenshtein('latte', 'latte'), 0);
      expect(FoodSearch.levenshtein('latte', 'late'), 1); // deletion
      expect(FoodSearch.levenshtein('latte', 'lattte'), 1); // insertion
      expect(FoodSearch.levenshtein('latte', 'lattw'), 1); // substitution
      expect(FoodSearch.levenshtein('latte', 'pane'), greaterThan(1));
    });
  });
}
