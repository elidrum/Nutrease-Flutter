import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/repository/diary_repository_impl.dart';
import 'package:nutrease_flutter/domain/model/food.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_food_item.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/in_memory_cache.dart';

/// One recorded PostgREST call.
class RecordedRequest {
  final String method;
  final Uri url;
  final String body;

  RecordedRequest(this.method, this.url, this.body);
}

/// One `pasto` row with two embedded `alimento_pasto` lines, for the
/// `getMealsForDate` embed query.
const List<Map<String, Object?>> _mealsForDateResponse = [
  {
    'IdPasto': 1,
    'IdFascicolo': 3,
    'Data': '2026-06-12',
    'Ora': '08:30:00',
    'Tipologia': 'Colazione',
    'Descrizione': null,
    'alimento_pasto': [
      {
        'IdAlimentoPasto': 1,
        'IdPasto': 1,
        'IdAlimento': 10,
        'QuantitaGrammi': 125,
        'UnitaMisuraOrig': 'g',
        'QuantitaOrig': 125,
        'LattosioCalc': 5.0,
        'SorbitoloCalc': 0.0,
        'GlutineCalc': 1.0,
        'CalorieCalc': 75.0,
      },
      {
        'IdAlimentoPasto': 2,
        'IdPasto': 1,
        'IdAlimento': 11,
        'QuantitaGrammi': 50,
        'UnitaMisuraOrig': 'g',
        'QuantitaOrig': 50,
        'LattosioCalc': 0.5,
        'SorbitoloCalc': 0.2,
        'GlutineCalc': 0.0,
        'CalorieCalc': 75.0,
      },
    ],
  },
];

void main() {
  late List<RecordedRequest> requests;
  late DiaryRepositoryImpl repository;

  const yogurt = Food(
    id: 10,
    name: 'Yogurt intero',
    unitConversions: {'coppetta': 125},
  );
  const pane = Food(id: 11, name: 'Pane comune');

  final meal = Meal(
    fascicoloId: 3,
    date: DateTime(2026, 6, 12),
    time: '08:30:00',
    type: MealType.breakfast,
    items: const [
      MealFoodItem(food: yogurt, amount: 1, unit: 'coppetta'),
      MealFoodItem(food: pane, amount: 50, unit: 'g'),
    ],
  );

  /// Routes every PostgREST request to a canned response and records it.
  MockClient buildClient() => MockClient((request) async {
        requests.add(RecordedRequest(
            request.method, request.url, utf8.decode(request.bodyBytes)));
        final path = request.url.path;
        final wantsSingleObject =
            request.headers['Accept']?.contains('vnd.pgrst.object') ?? false;

        if (request.method == 'POST' && path.endsWith('/pasto')) {
          return http.Response(
            wantsSingleObject ? '{"IdPasto": 7}' : '[{"IdPasto": 7}]',
            201,
            headers: {'content-type': 'application/json'},
            // postgrest reads response.request to pick the parsing strategy.
            request: request,
          );
        }
        if (request.method == 'GET' && path.endsWith('/pasto')) {
          return http.Response(
            jsonEncode(_mealsForDateResponse),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response('', 204, request: request);
      });

  setUp(() {
    requests = [];
    repository = DiaryRepositoryImpl(
      SupabaseClient('http://localhost:54321', 'anon-key',
          httpClient: buildClient()),
      buildInMemoryCacheDao(),
    );
  });

  group('addMeal', () {
    test('inserts pasto, then the lines with raw quantities and no *Calc',
        () async {
      final result = await repository.addMeal(meal);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, 7);

      final pastoInsert =
          requests.firstWhere((r) => r.method == 'POST' && r.url.path.endsWith('/pasto'));
      final pastoBody = jsonDecode(pastoInsert.body) as Map<String, dynamic>;
      expect(pastoBody['IdFascicolo'], 3);
      expect(pastoBody['Data'], '2026-06-12');
      expect(pastoBody['Ora'], '08:30:00');
      expect(pastoBody['Tipologia'], 'Colazione');
      expect(pastoBody.containsKey('IdPasto'), isFalse,
          reason: 'bigserial assigns the id');

      final linesInsert = requests.firstWhere(
          (r) => r.method == 'POST' && r.url.path.endsWith('/alimento_pasto'));
      final lines = jsonDecode(linesInsert.body) as List;
      expect(lines, hasLength(2));

      final first = lines[0] as Map<String, dynamic>;
      expect(first['IdPasto'], 7);
      expect(first['IdAlimento'], 10);
      expect(first['QuantitaGrammi'], 125); // 1 coppetta * 125
      expect(first['UnitaMisuraOrig'], 'coppetta');
      expect(first['QuantitaOrig'], 1);

      for (final line in lines.cast<Map<String, dynamic>>()) {
        expect(line.keys, isNot(contains('LattosioCalc')),
            reason: 'nutrients are computed by the DB trigger (ADR-0010)');
        expect(line.keys, isNot(contains('SorbitoloCalc')));
        expect(line.keys, isNot(contains('GlutineCalc')));
        expect(line.keys, isNot(contains('CalorieCalc')));
      }
    });
  });

  group('getMealsForDate', () {
    test('aggregates the *Calc columns into NutrientTotals', () async {
      final result = await repository.getMealsForDate(3, DateTime(2026, 6, 12));

      expect(result, isA<Ok<List<Meal>>>());
      final meals = (result as Ok<List<Meal>>).value;
      expect(meals, hasLength(1));
      // Sum of the two embedded lines' *Calc values.
      expect(meals.first.totals!.lactose, closeTo(5.5, 1e-9));
      expect(meals.first.totals!.sorbitol, closeTo(0.2, 1e-9));
      expect(meals.first.totals!.gluten, closeTo(1.0, 1e-9));
      expect(meals.first.totals!.kcal, closeTo(150, 1e-9));

      final get = requests.firstWhere(
          (r) => r.method == 'GET' && r.url.path.endsWith('/pasto'));
      expect(get.url.queryParameters['IdFascicolo'], 'eq.3');
      expect(get.url.queryParameters['Data'], 'eq.2026-06-12');
      expect(get.url.queryParameters['order'], contains('Ora'));
    });
  });

  group('deleteMeal', () {
    test('deletes the pasto filtered by id (lines cascade via FK)', () async {
      final result = await repository.deleteMeal(7);

      expect(result, isA<Ok<void>>());
      final del = requests.firstWhere(
          (r) => r.method == 'DELETE' && r.url.path.endsWith('/pasto'));
      expect(del.url.queryParameters['IdPasto'], 'eq.7');
    });
  });

  group('offline cache fallback (RF11)', () {
    test('returns the cached day when the network fails', () async {
      final dao = buildInMemoryCacheDao();
      final date = DateTime(2026, 6, 12);
      final cached = Meal(
        id: 1,
        fascicoloId: 3,
        date: date,
        time: '08:30:00',
        type: MealType.breakfast,
        items: const [],
        totals: const NutrientTotals(lactose: 5.5, kcal: 150),
      );
      await dao.replaceMeals(3, date, [cached]);

      final offlineRepo = DiaryRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key',
            httpClient: MockClient(
                (request) async => http.Response('boom', 500, request: request))),
        dao,
      );

      final result = await offlineRepo.getMealsForDate(3, date);

      expect(result, isA<Ok<List<Meal>>>());
      final meals = (result as Ok<List<Meal>>).value;
      expect(meals.single.id, 1);
      expect(meals.single.totals!.lactose, closeTo(5.5, 1e-9));
    });

    test('serves an empty list for a synced day with no meals', () async {
      final dao = buildInMemoryCacheDao();
      final date = DateTime(2026, 6, 12);
      // Giornata già scaricata ma senza pasti: la cache-aside la marca comunque
      // sincronizzata, quindi offline deve dare Ok([]), non un errore.
      await dao.replaceMeals(3, date, const []);

      final offlineRepo = DiaryRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key',
            httpClient: MockClient(
                (request) async => http.Response('boom', 500, request: request))),
        dao,
      );

      final result = await offlineRepo.getMealsForDate(3, date);

      expect(result, isA<Ok<List<Meal>>>());
      expect((result as Ok<List<Meal>>).value, isEmpty);
    });

    test('returns an error when the day was never synced', () async {
      final dao = buildInMemoryCacheDao();
      final offlineRepo = DiaryRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key',
            httpClient: MockClient(
                (request) async => http.Response('boom', 500, request: request))),
        dao,
      );

      final result = await offlineRepo.getMealsForDate(3, DateTime(2026, 6, 12));

      expect(result, isA<Err<List<Meal>>>());
    });
  });

  group('updateMeal', () {
    test('updates pasto and replaces the lines (delete + insert)', () async {
      final editing = Meal(
        id: 7,
        fascicoloId: meal.fascicoloId,
        date: meal.date,
        time: meal.time,
        type: MealType.dinner,
        items: meal.items,
      );

      final result = await repository.updateMeal(editing);

      expect(result, isA<Ok<void>>());

      final methods = [
        for (final r in requests) '${r.method} ${r.url.path.split('/').last}'
      ];
      expect(methods, [
        'PATCH pasto',
        'DELETE alimento_pasto',
        'POST alimento_pasto',
      ]);

      final patch = requests[0];
      expect(patch.url.queryParameters['IdPasto'], 'eq.7');
      final patchBody = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(patchBody['Tipologia'], 'Cena');

      expect(requests[1].url.queryParameters['IdPasto'], 'eq.7');
      final inserted = jsonDecode(requests[2].body) as List;
      expect(inserted, hasLength(2));
    });
  });
}
