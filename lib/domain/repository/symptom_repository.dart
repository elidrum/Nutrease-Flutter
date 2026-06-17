import '../../core/error/result.dart';
import '../model/symptom.dart';

/// Persistenza dei sintomi (`sintomo`), RF10/RF12.
abstract interface class SymptomRepository {
  /// Inserisce il sintomo; restituisce l'`IdSintomo` creato.
  Future<Result<int>> addSymptom(Symptom symptom);

  Future<Result<void>> updateSymptom(Symptom symptom);

  Future<Result<void>> deleteSymptom(int id);

  Future<Result<Symptom>> getSymptom(int id);

  /// I sintomi di [date] per [fascicoloId], ordinati per orario.
  ///
  /// Le letture sono cache-aside (`sqflite`): un fetch riuscito viene messo in
  /// cache e, quando la rete fallisce, il giorno in cache viene restituito per
  /// letture offline parziali (RF11).
  Future<Result<List<Symptom>>> getSymptomsForDate(
      int fascicoloId, DateTime date);
}
