import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/local/diary_cache_dao.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';

import '../helpers/in_memory_cache.dart';

void main() {
  late DiaryCacheDao dao;

  final day = DateTime(2026, 6, 12);
  final otherDay = DateTime(2026, 6, 13);

  Meal meal(int id, String time) => Meal(
        id: id,
        fascicoloId: 3,
        date: day,
        time: time,
        type: MealType.breakfast,
        items: const [],
        totals: const NutrientTotals(
            lactose: 5.5, sorbitol: 0.2, gluten: 1, kcal: 150),
      );

  Symptom symptom(int id, String time) => Symptom(
        id: id,
        fascicoloId: 3,
        date: day,
        time: time,
        type: SymptomType.cramps,
        severity: SymptomSeverity.severe,
      );

  setUp(() => dao = buildInMemoryCacheDao());

  test('upsertDay then getDay returns the same meals and symptoms', () async {
    await dao.upsertDay(
      3,
      day,
      [meal(1, '08:00:00')],
      [symptom(10, '12:00:00')],
    );

    final cached = await dao.getDay(3, day);
    expect(cached.meals, hasLength(1));
    expect(cached.meals.single.id, 1);
    expect(cached.meals.single.type, MealType.breakfast);
    expect(cached.meals.single.totals!.lactose, closeTo(5.5, 1e-9));
    expect(cached.symptoms, hasLength(1));
    expect(cached.symptoms.single.id, 10);
    expect(cached.symptoms.single.type, SymptomType.cramps);
    expect(cached.symptoms.single.severity, SymptomSeverity.severe);
  });

  test('upsertDay replaces only the targeted day (where/whereArgs scoping)',
      () async {
    await dao.upsertDay(3, day, [meal(1, '08:00:00')], [symptom(10, '09:00:00')]);
    await dao.upsertDay(3, otherDay, const [], const []);

    // The other day's empty upsert must not wipe the first day.
    final first = await dao.getDay(3, day);
    expect(first.meals, hasLength(1));
    expect(first.symptoms, hasLength(1));

    // Re-upserting the same day replaces its rows rather than appending.
    await dao.upsertDay(3, day, [meal(2, '07:00:00')], const []);
    final replaced = await dao.getDay(3, day);
    expect(replaced.meals.single.id, 2);
    expect(replaced.symptoms, isEmpty);
  });

  test('replaceMeals and replaceSymptoms do not clobber each other', () async {
    await dao.replaceMeals(3, day, [meal(1, '08:00:00')]);
    await dao.replaceSymptoms(3, day, [symptom(10, '09:00:00')]);

    // Re-writing meals leaves the cached symptoms intact (independent paths).
    await dao.replaceMeals(3, day, [meal(2, '07:00:00')]);
    final cached = await dao.getDay(3, day);
    expect(cached.meals.single.id, 2);
    expect(cached.symptoms.single.id, 10);
  });

  test('clear wipes both tables', () async {
    await dao.upsertDay(3, day, [meal(1, '08:00:00')], [symptom(10, '09:00:00')]);
    await dao.clear();
    final cached = await dao.getDay(3, day);
    expect(cached.meals, isEmpty);
    expect(cached.symptoms, isEmpty);
  });

  group('isDaySynced', () {
    test('a never-cached day is not synced', () async {
      expect(await dao.isDaySynced(3, day), isFalse);
    });

    test('caching meals marks the day as synced', () async {
      await dao.replaceMeals(3, day, [meal(1, '08:00:00')]);
      expect(await dao.isDaySynced(3, day), isTrue);
      // Scoped per (fascicolo, data): un altro giorno resta non sincronizzato.
      expect(await dao.isDaySynced(3, otherDay), isFalse);
    });

    test('caching symptoms marks the day as synced', () async {
      await dao.replaceSymptoms(3, day, [symptom(10, '09:00:00')]);
      expect(await dao.isDaySynced(3, day), isTrue);
    });

    test('an empty upsert still marks the day synced (synced-but-empty)',
        () async {
      await dao.upsertDay(3, day, const [], const []);
      expect(await dao.isDaySynced(3, day), isTrue);
      final cached = await dao.getDay(3, day);
      expect(cached.meals, isEmpty);
      expect(cached.symptoms, isEmpty);
    });

    test('clear wipes the synced markers too', () async {
      await dao.upsertDay(3, day, const [], const []);
      await dao.clear();
      expect(await dao.isDaySynced(3, day), isFalse);
    });
  });
}
