import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/daily_diary.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/usecase/delete_meal_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/delete_symptom_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_daily_diary_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_fascicolo_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/diary/diary_view_model.dart';

class _MockGetDailyDiaryUseCase extends Mock implements GetDailyDiaryUseCase {}

class _MockGetPatientFascicoloUseCase extends Mock
    implements GetPatientFascicoloUseCase {}

class _MockDeleteMealUseCase extends Mock implements DeleteMealUseCase {}

class _MockDeleteSymptomUseCase extends Mock implements DeleteSymptomUseCase {}

void main() {
  late _MockGetDailyDiaryUseCase getDaily;
  late _MockGetPatientFascicoloUseCase getFascicolo;
  late _MockDeleteMealUseCase deleteMeal;
  late _MockDeleteSymptomUseCase deleteSymptom;

  Meal meal(int id) => Meal(
        id: id,
        fascicoloId: 3,
        date: DateTime(2026, 6, 12),
        time: '08:00:00',
        type: MealType.breakfast,
        items: const [],
        totals: const NutrientTotals(lactose: 1, kcal: 100),
      );

  DailyDiary diaryWith(List<Meal> meals) =>
      DailyDiary(date: DateTime(2026, 6, 12), meals: meals);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    getDaily = _MockGetDailyDiaryUseCase();
    getFascicolo = _MockGetPatientFascicoloUseCase();
    deleteMeal = _MockDeleteMealUseCase();
    deleteSymptom = _MockDeleteSymptomUseCase();
  });

  DiaryViewModel buildViewModel({DateTime? initialDate}) => DiaryViewModel(
        getDailyDiaryUseCase: getDaily,
        getPatientFascicoloUseCase: getFascicolo,
        deleteMealUseCase: deleteMeal,
        deleteSymptomUseCase: deleteSymptom,
        initialDate: initialDate,
      );

  test('refresh resolves the fascicolo then loads the day (loading→success)',
      () async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any()))
        .thenAnswer((_) async => Ok(diaryWith([meal(1)])));

    final vm = buildViewModel(initialDate: DateTime(2026, 6, 12));
    expect(vm.state.diary, isA<Loading<DailyDiary>>());

    await vm.refresh();

    expect(vm.state.diary, isA<Success<DailyDiary>>());
    expect((vm.state.diary as Success<DailyDiary>).data.meals, hasLength(1));
    verify(() => getFascicolo()).called(1);
    verify(() => getDaily(3, DateTime(2026, 6, 12))).called(1);
  });

  test('selectDate switches the date and reloads it', () async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any()))
        .thenAnswer((_) async => Ok(diaryWith(const [])));

    final vm = buildViewModel(initialDate: DateTime(2026, 6, 12));
    vm.selectDate(DateTime(2026, 6, 15, 10, 30));
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.selectedDate, DateTime(2026, 6, 15));
    verify(() => getDaily(3, DateTime(2026, 6, 15))).called(1);
  });

  test('a missing active fascicolo surfaces the error and skips the load',
      () async {
    when(() => getFascicolo()).thenAnswer(
        (_) async => const Err(NotFoundError('Nessun fascicolo attivo')));

    final vm = buildViewModel();
    await vm.refresh();

    expect(vm.state.diary, isA<Failure<DailyDiary>>());
    expect((vm.state.diary as Failure<DailyDiary>).error.message,
        'Nessun fascicolo attivo');
    verifyNever(() => getDaily(any(), any()));
  });

  test('the fascicolo is resolved once and cached across refreshes', () async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any()))
        .thenAnswer((_) async => Ok(diaryWith(const [])));

    final vm = buildViewModel();
    await vm.refresh();
    await vm.refresh();

    verify(() => getFascicolo()).called(1);
    verify(() => getDaily(any(), any())).called(2);
  });

  test('deleteMeal removes the entry and re-fetches the day', () async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => deleteMeal(1)).thenAnswer((_) async => const Ok(null));
    // First load has the meal; the post-delete re-fetch returns it gone.
    var loadCount = 0;
    when(() => getDaily(any(), any())).thenAnswer((_) async {
      loadCount++;
      return Ok(diaryWith(loadCount == 1 ? [meal(1)] : const []));
    });

    final vm = buildViewModel();
    await vm.refresh();
    expect((vm.state.diary as Success<DailyDiary>).data.meals, hasLength(1));

    final ok = await vm.deleteMeal(1);

    expect(ok, isTrue);
    verify(() => deleteMeal(1)).called(1);
    expect((vm.state.diary as Success<DailyDiary>).data.meals, isEmpty);
  });

  test('a failed deleteMeal returns false', () async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any()))
        .thenAnswer((_) async => Ok(diaryWith([meal(1)])));
    when(() => deleteMeal(1))
        .thenAnswer((_) async => const Err(NetworkError()));

    final vm = buildViewModel();
    await vm.refresh();
    final ok = await vm.deleteMeal(1);

    expect(ok, isFalse);
  });
}
