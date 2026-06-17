import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/food.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_food_item.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/repository/diary_repository.dart';
import 'package:nutrease_flutter/domain/repository/food_repository.dart';
import 'package:nutrease_flutter/domain/repository/patient_clinical_file_repository.dart';
import 'package:nutrease_flutter/domain/usecase/add_meal_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_meal_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_fascicolo_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/search_foods_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/update_meal_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/diary/add_meal_view_model.dart';

class _MockFoodRepository extends Mock implements FoodRepository {}

class _MockDiaryRepository extends Mock implements DiaryRepository {}

class _MockClinicalFileRepository extends Mock
    implements PatientClinicalFileRepository {}

const _pasta = Food(id: 1, name: 'Pasta');
const _latte = Food(id: 2, name: 'Latte intero');

void main() {
  late _MockFoodRepository foodRepo;
  late _MockDiaryRepository diaryRepo;
  late _MockClinicalFileRepository fileRepo;

  setUpAll(() {
    registerFallbackValue(Meal(
      fascicoloId: 0,
      date: DateTime(2026),
      time: '00:00:00',
      type: MealType.lunch,
      items: const [],
    ));
  });

  setUp(() {
    foodRepo = _MockFoodRepository();
    diaryRepo = _MockDiaryRepository();
    fileRepo = _MockClinicalFileRepository();
  });

  AddMealViewModel buildViewModel({int? mealId}) => AddMealViewModel(
        searchFoodsUseCase: SearchFoodsUseCase(foodRepo),
        addMealUseCase: AddMealUseCase(diaryRepo),
        updateMealUseCase: UpdateMealUseCase(diaryRepo),
        getMealUseCase: GetMealUseCase(diaryRepo),
        getPatientFascicoloUseCase: GetPatientFascicoloUseCase(fileRepo),
        mealId: mealId,
        debounceDuration: const Duration(milliseconds: 30),
      );

  group('search (RF8)', () {
    test('debounces rapid input into a single dataset query', () async {
      when(() => foodRepo.getAllFoods())
          .thenAnswer((_) async => const Ok([_pasta, _latte]));

      final vm = buildViewModel();
      vm.onQueryChanged('p');
      vm.onQueryChanged('pa');
      vm.onQueryChanged('pasta');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      verify(() => foodRepo.getAllFoods()).called(1);
      final results = vm.state.searchResults;
      expect(results, isA<Success<List<Food>>>());
      expect((results as Success<List<Food>>).data.single.name, 'Pasta');
    });

    test('clearing the query resets results without querying', () async {
      final vm = buildViewModel();
      vm.onQueryChanged('pasta');
      vm.onQueryChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 120));

      verifyNever(() => foodRepo.getAllFoods());
      expect(vm.state.searchResults, isA<Success<List<Food>>>());
    });
  });

  group('item composition (RF9)', () {
    test('addItem appends and clears the search; removeItem drops by index',
        () {
      final vm = buildViewModel();

      vm.addItem(_pasta, 80, 'g');
      vm.addItem(_latte, 200, 'g');
      expect(vm.state.selectedItems, hasLength(2));
      expect(vm.state.searchQuery, isEmpty);

      vm.removeItem(0);
      expect(vm.state.selectedItems.single.food.name, 'Latte intero');
    });

    test('a non-positive quantity is rejected', () {
      final vm = buildViewModel();
      vm.addItem(_pasta, 0, 'g');
      expect(vm.state.selectedItems, isEmpty);
    });
  });

  group('submit (ADR-0013: insert vs edit)', () {
    test('without meal_id resolves the fascicolo and inserts', () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => diaryRepo.addMeal(any())).thenAnswer((_) async => const Ok(7));

      final vm = buildViewModel();
      vm.addItem(_pasta, 80, 'g');
      await vm.submit();

      final captured =
          verify(() => diaryRepo.addMeal(captureAny())).captured.single as Meal;
      expect(captured.id, isNull);
      expect(captured.fascicoloId, 3);
      verifyNever(() => diaryRepo.updateMeal(any()));
      expect(vm.state.saved, isTrue);
    });

    test('with meal_id prefills via getMeal and updates', () async {
      final existing = Meal(
        id: 5,
        fascicoloId: 3,
        date: DateTime(2026, 6, 10),
        time: '12:30:00',
        type: MealType.dinner,
        items: const [MealFoodItem(food: _pasta, amount: 80, unit: 'g')],
      );
      when(() => diaryRepo.getMeal(5)).thenAnswer((_) async => Ok(existing));
      when(() => diaryRepo.updateMeal(any()))
          .thenAnswer((_) async => const Ok(null));

      final vm = buildViewModel(mealId: 5);
      await vm.init();
      expect(vm.state.isEditing, isTrue);
      expect(vm.state.type, MealType.dinner);
      expect(vm.state.selectedItems, hasLength(1));

      await vm.submit();

      final captured = verify(() => diaryRepo.updateMeal(captureAny()))
          .captured
          .single as Meal;
      expect(captured.id, 5);
      expect(captured.fascicoloId, 3);
      verifyNever(() => diaryRepo.addMeal(any()));
      // The fascicolo comes from the loaded meal, not from a new lookup.
      verifyNever(() => fileRepo.getActiveFascicoloId());
      expect(vm.state.saved, isTrue);
    });

    test('is single-flight: a double submit performs one insert', () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => diaryRepo.addMeal(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Ok(7);
      });

      final vm = buildViewModel();
      vm.addItem(_pasta, 80, 'g');
      final first = vm.submit();
      final second = vm.submit();
      await Future.wait([first, second]);

      verify(() => diaryRepo.addMeal(any())).called(1);
    });

    test('a failed insert surfaces the error and does not mark saved',
        () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => diaryRepo.addMeal(any()))
          .thenAnswer((_) async => const Err(NetworkError()));

      final vm = buildViewModel();
      vm.addItem(_pasta, 80, 'g');
      await vm.submit();

      expect(vm.state.error, isNotNull);
      expect(vm.state.saved, isFalse);
      expect(vm.state.isSaving, isFalse);
    });

    test('a missing active fascicolo blocks the save with its message',
        () async {
      when(() => fileRepo.getActiveFascicoloId()).thenAnswer(
          (_) async => const Err(NotFoundError('Nessun fascicolo attivo')));

      final vm = buildViewModel();
      vm.addItem(_pasta, 80, 'g');
      await vm.submit();

      expect(vm.state.error, 'Nessun fascicolo attivo');
      verifyNever(() => diaryRepo.addMeal(any()));
    });

    test('a future date blocks the save before any lookup', () async {
      final vm = buildViewModel();
      vm.addItem(_pasta, 80, 'g');
      vm.setDate(DateTime.now().add(const Duration(days: 2)));
      await vm.submit();

      expect(vm.state.error, isNotNull);
      verifyNever(() => fileRepo.getActiveFascicoloId());
      verifyNever(() => diaryRepo.addMeal(any()));
    });
  });
}
