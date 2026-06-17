import '../../core/error/result.dart';
import '../model/daily_diary.dart';
import '../model/meal.dart';
import '../model/symptom.dart';
import '../repository/diary_repository.dart';
import '../repository/symptom_repository.dart';

/// Costruisce il diario giornaliero fuso (RF11) leggendo pasti e sintomi in
/// parallelo e assemblando un [DailyDiary] (che espone la timeline fusa).
///
/// Entrambe le letture sottostanti sono cache-aside (`sqflite`): a rete giù
/// ciascuna ripiega sulle righe in cache, così un giorno già caricato resta
/// leggibile offline. La costruzione fallisce solo quando falliscono **entrambe**
/// le letture (niente rete e niente cache); un solo lato in errore degrada a un
/// giorno parziale invece di nascondere i dati comunque arrivati.
class GetDailyDiaryUseCase {
  final DiaryRepository _diaryRepository;
  final SymptomRepository _symptomRepository;

  const GetDailyDiaryUseCase(this._diaryRepository, this._symptomRepository);

  Future<Result<DailyDiary>> call(int fascicoloId, DateTime date) async {
    final results = await Future.wait([
      _diaryRepository.getMealsForDate(fascicoloId, date),
      _symptomRepository.getSymptomsForDate(fascicoloId, date),
    ]);
    final mealsResult = results[0] as Result<List<Meal>>;
    final symptomsResult = results[1] as Result<List<Symptom>>;

    if (mealsResult is Err<List<Meal>> &&
        symptomsResult is Err<List<Symptom>>) {
      return Err(mealsResult.error);
    }

    final meals = switch (mealsResult) {
      Ok(:final value) => value,
      Err() => const <Meal>[],
    };
    final symptoms = switch (symptomsResult) {
      Ok(:final value) => value,
      Err() => const <Symptom>[],
    };

    return Ok(DailyDiary(date: date, meals: meals, symptoms: symptoms));
  }
}
