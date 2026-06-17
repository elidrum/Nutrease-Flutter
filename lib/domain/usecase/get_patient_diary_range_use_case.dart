import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/diary_date_range.dart';
import '../model/nutrient_totals.dart';
import '../model/patient_diary_day.dart';
import '../repository/diary_repository.dart';
import '../repository/symptom_repository.dart';

/// Costruisce il diario read-only del paziente per un intervallo di date
/// (RF19/RF20).
///
/// Porta ADR-0016 (riuso di `DiaryRepository`/`SymptomRepository` — niente nuovo
/// repository per il diario) e ADR-0017 (cap dell'intervallo a 92 giorni prima
/// del fan-out):
/// * valida il cap e altrimenti fallisce subito con un [ValidationError];
/// * legge ogni giorno **in parallelo** (anche le due letture per giorno girano
///   in concorrenza), aggregando i [NutrientTotals] calcolati dal trigger;
/// * restituisce i giorni non vuoti, dal più recente.
///
/// Il filtro nutriente **non** si applica qui: si restituisce l'intero intervallo
/// così la UI può evidenziare (non tagliare) il nutriente selezionato.
class GetPatientDiaryRangeUseCase {
  final DiaryRepository _diaryRepository;
  final SymptomRepository _symptomRepository;

  const GetPatientDiaryRangeUseCase(
      this._diaryRepository, this._symptomRepository);

  Future<Result<List<PatientDiaryDay>>> call(
      int fascicoloId, DiaryDateRange range) async {
    if (range.exceedsCap) {
      return const Err(
          ValidationError('Il periodo non può superare 92 giorni'));
    }

    final dayResults = await Future.wait(
      range.dates.map((day) => _buildDay(fascicoloId, day)),
    );

    final days = <PatientDiaryDay>[];
    for (final result in dayResults) {
      switch (result) {
        case Ok(value: final day):
          if (!day.isEmpty) days.add(day);
        case Err(error: final error):
          return Err(error);
      }
    }
    days.sort((a, b) => b.date.compareTo(a.date));
    return Ok(days);
  }

  /// Legge pasti e sintomi di un giorno in concorrenza e ne aggrega i totali.
  Future<Result<PatientDiaryDay>> _buildDay(
      int fascicoloId, DateTime day) async {
    // Avvio entrambe le letture, poi le attendo: girano in parallelo nel giorno.
    final mealsFuture = _diaryRepository.getMealsForDate(fascicoloId, day);
    final symptomsFuture =
        _symptomRepository.getSymptomsForDate(fascicoloId, day);
    final mealsResult = await mealsFuture;
    final symptomsResult = await symptomsFuture;

    return mealsResult.fold(
      ok: (meals) => symptomsResult.fold(
        ok: (symptoms) => Ok(PatientDiaryDay(
          date: day,
          meals: meals,
          symptoms: symptoms,
          dayTotals: meals.fold(
            NutrientTotals.zero,
            (acc, meal) => acc + (meal.totals ?? NutrientTotals.zero),
          ),
        )),
        err: (error) => Err(error),
      ),
      err: (error) => Err(error),
    );
  }
}
