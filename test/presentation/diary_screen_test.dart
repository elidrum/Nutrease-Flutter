import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/daily_diary.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';
import 'package:nutrease_flutter/domain/usecase/delete_meal_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/delete_symptom_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_daily_diary_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_fascicolo_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/diary/diary_screen.dart';
import 'package:provider/provider.dart';

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

  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    await initializeDateFormatting('it_IT');
  });

  setUp(() {
    getDaily = _MockGetDailyDiaryUseCase();
    getFascicolo = _MockGetPatientFascicoloUseCase();
    deleteMeal = _MockDeleteMealUseCase();
    deleteSymptom = _MockDeleteSymptomUseCase();
  });

  Widget harness() => MultiProvider(
        providers: [
          Provider<GetDailyDiaryUseCase>.value(value: getDaily),
          Provider<GetPatientFascicoloUseCase>.value(value: getFascicolo),
          Provider<DeleteMealUseCase>.value(value: deleteMeal),
          Provider<DeleteSymptomUseCase>.value(value: deleteSymptom),
        ],
        child: MaterialApp(home: DiaryScreen(initialDate: DateTime(2026, 6, 12))),
      );

  testWidgets('renders the timeline with a meal and a symptom card',
      (tester) async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any())).thenAnswer(
      (_) async => Ok(DailyDiary(
        date: DateTime(2026, 6, 12),
        meals: [
          Meal(
            id: 1,
            fascicoloId: 3,
            date: DateTime(2026, 6, 12),
            time: '08:30:00',
            type: MealType.breakfast,
            items: const [],
            totals: const NutrientTotals(lactose: 5.5, kcal: 150),
          ),
        ],
        symptoms: [
          Symptom(
            id: 10,
            fascicoloId: 3,
            date: DateTime(2026, 6, 12),
            time: '10:00:00',
            type: SymptomType.bloating,
            severity: SymptomSeverity.severe,
          ),
        ],
      )),
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Meal type label and symptom type/severity labels (Italian).
    expect(find.text('Colazione'), findsOneWidget);
    expect(find.text('Gonfiore'), findsOneWidget);
    expect(find.text('Grave'), findsOneWidget);
    // Date strip in dd/MM/yyyy.
    expect(find.text('12/06/2026'), findsOneWidget);
  });

  testWidgets('shows the empty state when the day has no entries',
      (tester) async {
    when(() => getFascicolo()).thenAnswer((_) async => const Ok(3));
    when(() => getDaily(any(), any()))
        .thenAnswer((_) async => Ok(DailyDiary(date: DateTime(2026, 6, 12))));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Nessuna voce'), findsOneWidget);
  });
}
