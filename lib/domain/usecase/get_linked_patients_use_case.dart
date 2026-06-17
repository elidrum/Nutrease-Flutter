import '../../core/error/result.dart';
import '../model/linked_patient.dart';
import '../repository/linked_patients_repository.dart';

/// Carica i pazienti collegati dello specialista (RF18). Delega sottile; le RLS
/// limitano le righe allo specialista loggato e il repository filtra i fascicoli
/// attivi.
class GetLinkedPatientsUseCase {
  final LinkedPatientsRepository _repository;

  const GetLinkedPatientsUseCase(this._repository);

  Future<Result<List<LinkedPatient>>> call() => _repository.getLinkedPatients();
}
