import '../../core/error/result.dart';
import '../repository/symptom_repository.dart';

/// Elimina un sintomo per id (RF12).
class DeleteSymptomUseCase {
  final SymptomRepository _symptomRepository;

  const DeleteSymptomUseCase(this._symptomRepository);

  Future<Result<void>> call(int id) => _symptomRepository.deleteSymptom(id);
}
