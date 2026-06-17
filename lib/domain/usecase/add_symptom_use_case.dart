import '../../core/error/result.dart';
import '../model/symptom.dart';
import '../repository/symptom_repository.dart';

/// Registra un nuovo sintomo (RF10); restituisce l'`IdSintomo` creato.
class AddSymptomUseCase {
  final SymptomRepository _symptomRepository;

  const AddSymptomUseCase(this._symptomRepository);

  Future<Result<int>> call(Symptom symptom) =>
      _symptomRepository.addSymptom(symptom);
}
