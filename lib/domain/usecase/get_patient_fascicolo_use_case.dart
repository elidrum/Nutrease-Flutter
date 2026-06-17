import '../../core/error/result.dart';
import '../repository/patient_clinical_file_repository.dart';

/// Risolve l'id del fascicolo clinico attivo, necessario per scrivere nel diario.
class GetPatientFascicoloUseCase {
  final PatientClinicalFileRepository _repository;

  const GetPatientFascicoloUseCase(this._repository);

  Future<Result<int>> call() => _repository.getActiveFascicoloId();
}
