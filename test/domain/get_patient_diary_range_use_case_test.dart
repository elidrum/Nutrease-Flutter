import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/diary_date_range.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/model/patient_diary_day.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';
import 'package:nutrease_flutter/domain/repository/diary_repository.dart';
import 'package:nutrease_flutter/domain/repository/symptom_repository.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_diary_range_use_case.dart';

class _MockDiaryRepo extends Mock implements DiaryRepository {}

class _MockSymptomRepo extends Mock implements SymptomRepository {}

const _fascicoloId = 7;

void main() {
  late _MockDiaryRepo diary;
  late _MockSymptomRepo symptom;
  late GetPatientDiaryRangeUseCase useCase;

  Meal mealOn(DateTime date, {required NutrientTotals totals}) => Meal(
        id: date.day,
        fascicoloId: _fascicoloId,
        date: date,
        time: '08:00:00',
        type: MealType.breakfast,
        items: const [],
        totals: totals,
      );

  Symptom symptomOn(DateTime date) => Symptom(
        id: date.day,
        fascicoloId: _fascicoloId,
        date: date,
        time: '09:00:00',
        type: SymptomType.bloating,
        severity: SymptomSeverity.mild,
      );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    diary = _MockDiaryRepo();
    symptom = _MockSymptomRepo();
    useCase = GetPatientDiaryRangeUseCase(diary, symptom);
  });

  test('a range over 92 days fails fast without touching the repos', () async {
    final from = DateTime(2026, 1, 1);
    final range = DiaryDateRange.custom(from, from.add(const Duration(days: 92)));

    final result = await useCase(_fascicoloId, range);

    expect((result as Err).error, isA<ValidationError>());
    verifyNever(() => diary.getMealsForDate(any(), any()));
    verifyNever(() => symptom.getSymptomsForDate(any(), any()));
  });

  test('fans out per day, aggregates day totals, and sorts newest first',
      () async {
    final range =
        DiaryDateRange.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 11));

    when(() => diary.getMealsForDate(any(), any())).thenAnswer((inv) async {
      final day = (inv.positionalArguments[1] as DateTime).day;
      if (day == 10) {
        return Ok([
          mealOn(DateTime(2026, 6, 10),
              totals: const NutrientTotals(lactose: 1, kcal: 100)),
          mealOn(DateTime(2026, 6, 10),
              totals: const NutrientTotals(lactose: 2, kcal: 50)),
        ]);
      }
      if (day == 11) {
        return Ok([
          mealOn(DateTime(2026, 6, 11),
              totals: const NutrientTotals(gluten: 4)),
        ]);
      }
      return const Ok(<Meal>[]);
    });
    when(() => symptom.getSymptomsForDate(any(), any())).thenAnswer((inv) async {
      final day = (inv.positionalArguments[1] as DateTime).day;
      return Ok(day == 11 ? [symptomOn(DateTime(2026, 6, 11))] : <Symptom>[]);
    });

    final result = await useCase(_fascicoloId, range);
    final days = (result as Ok<List<PatientDiaryDay>>).value;

    expect(days, hasLength(2));
    // Newest first.
    expect(days.first.date, DateTime(2026, 6, 11));
    expect(days.last.date, DateTime(2026, 6, 10));
    // Day totals aggregate the per-meal trigger-computed totals.
    expect(days.last.dayTotals.lactose, 3);
    expect(days.last.dayTotals.kcal, 150);
    expect(days.first.dayTotals.gluten, 4);
    // The 11th carries both a meal and a symptom in its timeline.
    expect(days.first.timeline, hasLength(2));
  });

  test('excludes days with no meals and no symptoms', () async {
    final range =
        DiaryDateRange.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 12));

    when(() => diary.getMealsForDate(any(), any())).thenAnswer((inv) async {
      final day = (inv.positionalArguments[1] as DateTime).day;
      // Only the 10th and 12th have a meal; the 11th is empty.
      return Ok(day == 11
          ? <Meal>[]
          : [mealOn(DateTime(2026, 6, day), totals: NutrientTotals.zero)]);
    });
    when(() => symptom.getSymptomsForDate(any(), any()))
        .thenAnswer((_) async => const Ok(<Symptom>[]));

    final result = await useCase(_fascicoloId, range);
    final days = (result as Ok<List<PatientDiaryDay>>).value;

    expect(days, hasLength(2));
    expect(days.map((d) => d.date.day), [12, 10]);
  });

  test('propagates a repository error from any day', () async {
    final range =
        DiaryDateRange.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 11));

    when(() => diary.getMealsForDate(any(), any())).thenAnswer((inv) async {
      final day = (inv.positionalArguments[1] as DateTime).day;
      if (day == 11) return const Err(NetworkError());
      return Ok([mealOn(DateTime(2026, 6, 10), totals: NutrientTotals.zero)]);
    });
    when(() => symptom.getSymptomsForDate(any(), any()))
        .thenAnswer((_) async => const Ok(<Symptom>[]));

    final result = await useCase(_fascicoloId, range);

    expect((result as Err).error, isA<NetworkError>());
  });
}
