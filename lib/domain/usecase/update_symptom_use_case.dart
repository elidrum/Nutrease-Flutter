import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/symptom.dart';
import '../repository/symptom_repository.dart';

/// Aggiorna un sintomo esistente (modifica RF12).
class UpdateSymptomUseCase {
  final SymptomRepository _symptomRepository;

  const UpdateSymptomUseCase(this._symptomRepository);

  Future<Result<void>> call(Symptom symptom) async {
    if (symptom.id == null) {
      return const Err(
          ValidationError('Sintomo senza ID: impossibile aggiornare.'));
    }
    return _symptomRepository.updateSymptom(symptom);
  }
}
