import '../../core/error/result.dart';
import '../model/symptom.dart';
import '../repository/symptom_repository.dart';

/// Carica un singolo sintomo, per pre-compilare il form di modifica (ADR-0013).
class GetSymptomUseCase {
  final SymptomRepository _symptomRepository;

  const GetSymptomUseCase(this._symptomRepository);

  Future<Result<Symptom>> call(int id) => _symptomRepository.getSymptom(id);
}
