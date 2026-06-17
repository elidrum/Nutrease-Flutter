import '../../core/error/result.dart';
import '../model/symptom.dart';
import '../repository/symptom_repository.dart';

/// Carica i sintomi di una data per un fascicolo clinico (RF11).
class GetSymptomsForDateUseCase {
  final SymptomRepository _symptomRepository;

  const GetSymptomsForDateUseCase(this._symptomRepository);

  Future<Result<List<Symptom>>> call(int fascicoloId, DateTime date) =>
      _symptomRepository.getSymptomsForDate(fascicoloId, date);
}
