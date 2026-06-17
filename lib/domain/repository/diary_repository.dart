import '../../core/error/result.dart';
import '../model/meal.dart';

/// Persistenza dei pasti del diario (`pasto` + `alimento_pasto`).
abstract interface class DiaryRepository {
  /// Inserisce il pasto e le sue righe; restituisce l'`IdPasto` creato.
  Future<Result<int>> addMeal(Meal meal);

  /// Aggiorna la testata del pasto e sostituisce tutte le sue righe (così il
  /// trigger DB ricalcola i nutrienti).
  Future<Result<void>> updateMeal(Meal meal);

  Future<Result<Meal>> getMeal(int mealId);

  /// Pasti di [date] per [fascicoloId], ordinati per orario (RF11).
  ///
  /// Le letture sono cache-aside (`sqflite`): un fetch riuscito viene messo in
  /// cache e, quando la rete fallisce, si restituisce il giorno in cache per
  /// letture offline parziali.
  Future<Result<List<Meal>>> getMealsForDate(int fascicoloId, DateTime date);

  /// Elimina il pasto; le sue righe `alimento_pasto` cadono in cascata (FK, RF12).
  Future<Result<void>> deleteMeal(int mealId);
}
