import 'daily_diary.dart';
import 'meal.dart';
import 'nutrient_totals.dart';
import 'symptom.dart';

/// Un giorno del diario di un paziente come lo vede lo specialista (RF19): i
/// suoi pasti, i sintomi e i [dayTotals] aggregati.
///
/// La [timeline] mista riusa la fusione pura di [DailyDiary] (ADR-0016: niente
/// duplicazione della logica di ordinamento pasti+sintomi).
class PatientDiaryDay {
  final DateTime date;
  final List<Meal> meals;
  final List<Symptom> symptoms;

  /// Somma dei totali nutrienti dei pasti del giorno, calcolati dal trigger.
  final NutrientTotals dayTotals;

  const PatientDiaryDay({
    required this.date,
    this.meals = const [],
    this.symptoms = const [],
    this.dayTotals = NutrientTotals.zero,
  });

  bool get isEmpty => meals.isEmpty && symptoms.isEmpty;

  /// Pasti + sintomi fusi e ordinati per orario (crescente), riusando
  /// [DailyDiary.timeline].
  List<DiaryEntry> get timeline =>
      DailyDiary(date: date, meals: meals, symptoms: symptoms).timeline;
}
