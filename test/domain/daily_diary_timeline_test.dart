import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/daily_diary.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';

void main() {
  final date = DateTime(2026, 6, 12);

  Meal meal(int id, String time) => Meal(
        id: id,
        fascicoloId: 3,
        date: date,
        time: time,
        type: MealType.lunch,
        items: const [],
        totals: const NutrientTotals(lactose: 1, kcal: 100),
      );

  Symptom symptom(int id, String time) => Symptom(
        id: id,
        fascicoloId: 3,
        date: date,
        time: time,
        type: SymptomType.bloating,
        severity: SymptomSeverity.mild,
      );

  group('timeline', () {
    test('merges meals and symptoms ordered by time of day', () {
      final diary = DailyDiary(
        date: date,
        meals: [meal(1, '12:30:00'), meal(2, '08:00:00')],
        symptoms: [symptom(10, '10:15:00'), symptom(11, '20:00:00')],
      );

      final times = diary.timeline.map((e) => e.time).toList();
      expect(times, ['08:00:00', '10:15:00', '12:30:00', '20:00:00']);
    });

    test('is stable at equal times (meals before symptoms, then input order)',
        () {
      final diary = DailyDiary(
        date: date,
        meals: [meal(1, '09:00:00'), meal(2, '09:00:00')],
        symptoms: [symptom(10, '09:00:00')],
      );

      final entries = diary.timeline;
      expect(entries[0], isA<MealEntry>());
      expect((entries[0] as MealEntry).meal.id, 1);
      expect(entries[1], isA<MealEntry>());
      expect((entries[1] as MealEntry).meal.id, 2);
      expect(entries[2], isA<SymptomEntry>());
      expect((entries[2] as SymptomEntry).symptom.id, 10);
    });

    test('empty diary yields an empty timeline', () {
      final diary = DailyDiary(date: date);
      expect(diary.isEmpty, isTrue);
      expect(diary.timeline, isEmpty);
    });
  });

  group('totals', () {
    test('sums every meal total', () {
      final diary = DailyDiary(
        date: date,
        meals: [meal(1, '08:00:00'), meal(2, '12:00:00')],
      );
      expect(diary.totals.lactose, 2);
      expect(diary.totals.kcal, 200);
    });
  });
}
