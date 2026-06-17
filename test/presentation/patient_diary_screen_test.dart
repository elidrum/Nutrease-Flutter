import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/core/strings/it_strings.dart';
import 'package:nutrease_flutter/domain/model/diary_date_range.dart';
import 'package:nutrease_flutter/domain/model/meal.dart';
import 'package:nutrease_flutter/domain/model/meal_type.dart';
import 'package:nutrease_flutter/domain/model/nutrient_totals.dart';
import 'package:nutrease_flutter/domain/model/patient_diary_day.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_diary_range_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/patientdiary/patient_diary_screen.dart';
import 'package:provider/provider.dart';

class _MockGetRange extends Mock implements GetPatientDiaryRangeUseCase {}

void main() {
  late _MockGetRange getRange;

  setUpAll(() async {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(DiaryDateRange.today());
    await initializeDateFormatting('it_IT');
  });

  setUp(() => getRange = _MockGetRange());

  PatientDiaryDay dayWithEntries() => PatientDiaryDay(
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
        dayTotals: const NutrientTotals(lactose: 5.5, kcal: 150),
      );

  Widget harness() => MultiProvider(
        providers: [
          Provider<GetPatientDiaryRangeUseCase>.value(value: getRange),
        ],
        child: const MaterialApp(
          home: PatientDiaryScreen(fascicoloId: 3, patientName: 'Mario Rossi'),
        ),
      );

  void useNarrowPhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('read-only: title, filter chips and cards, but no FAB',
      (tester) async {
    useNarrowPhone(tester);
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => Ok([dayWithEntries()]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The app bar names the patient.
    expect(find.text(ItStrings.patientDiaryTitle('Mario Rossi')),
        findsOneWidget);
    // No edit affordances on the read-only view.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    // Period + nutrient filter chips.
    expect(find.text(ItStrings.periodToday), findsOneWidget);
    expect(find.text(ItStrings.periodCustom), findsOneWidget);
    expect(find.text(ItStrings.nutrientAll), findsWidgets);
    // Meal + symptom cards render with Italian labels.
    expect(find.text('Colazione'), findsOneWidget);
    expect(find.text('Gonfiore'), findsOneWidget);
    expect(find.textContaining('giugno 2026'), findsOneWidget);
  });

  testWidgets('nutrient highlight never trims the list (RF20)', (tester) async {
    useNarrowPhone(tester);
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => Ok([dayWithEntries()]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Select the lactose highlight.
    await tester.tap(find.widgetWithText(ChoiceChip, ItStrings.nutrientLactose));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The list is unchanged: both the meal and the symptom are still shown.
    expect(find.text('Colazione'), findsOneWidget);
    expect(find.text('Gonfiore'), findsOneWidget);
  });

  testWidgets('survives 200% font scale without overflow', (tester) async {
    useNarrowPhone(tester);
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => Ok([dayWithEntries()]));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GetPatientDiaryRangeUseCase>.value(value: getRange),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: PatientDiaryScreen(
                fascicoloId: 3, patientName: 'Mario Rossi'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
