import 'meal.dart';
import 'nutrient_totals.dart';
import 'symptom.dart';

/// Il diario di un singolo giorno: i suoi pasti e sintomi, più la [timeline]
/// che li fonde (RF11). La fusione e i [totals] del giorno sono logica pura e
/// testabile: niente framework, niente I/O.
class DailyDiary {
  final DateTime date;
  final List<Meal> meals;
  final List<Symptom> symptoms;

  const DailyDiary({
    required this.date,
    this.meals = const [],
    this.symptoms = const [],
  });

  bool get isEmpty => meals.isEmpty && symptoms.isEmpty;

  /// Somma dei nutrienti di tutti i pasti, già calcolati dal trigger.
  NutrientTotals get totals =>
      meals.fold(NutrientTotals.zero, (acc, m) => acc + (m.totals ?? NutrientTotals.zero));

  /// Pasti e sintomi fusi e ordinati per orario (crescente).
  ///
  /// Stabile a parità di orario: i pari mantengono l'ordine di costruzione
  /// (prima i pasti, poi i sintomi, e dentro ciascun gruppo l'ordine della
  /// lista originale). `time` è `HH:mm:ss` a larghezza fissa, quindi il
  /// confronto lessicografico è già cronologico.
  List<DiaryEntry> get timeline {
    final entries = <DiaryEntry>[
      for (final meal in meals) MealEntry(meal),
      for (final symptom in symptoms) SymptomEntry(symptom),
    ];
    final indexed = entries.indexed.toList();
    indexed.sort((a, b) {
      final byTime = a.$2.time.compareTo(b.$2.time);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
    return [for (final entry in indexed) entry.$2];
  }
}

/// Una riga della timeline: un pasto o un sintomo, con un [time] comune che
/// serve solo a ordinarli.
sealed class DiaryEntry {
  const DiaryEntry();

  /// Orario `HH:mm:ss` usato per ordinare la timeline.
  String get time;
}

class MealEntry extends DiaryEntry {
  final Meal meal;
  const MealEntry(this.meal);

  @override
  String get time => meal.time;
}

class SymptomEntry extends DiaryEntry {
  final Symptom symptom;
  const SymptomEntry(this.symptom);

  @override
  String get time => symptom.time;
}
