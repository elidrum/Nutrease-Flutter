import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/specialist.dart';
import '../model/user_role.dart';
import '../repository/auth_repository.dart';
import '../repository/specialist_directory_repository.dart';

/// Risolve lo specialista attualmente collegato al paziente (o `null`). Guardia
/// di ruolo: solo paziente — ricava il codice fiscale del paziente dall'utente
/// corrente e legge il fascicolo clinico attivo.
class GetLinkedSpecialistUseCase {
  final AuthRepository _authRepository;
  final SpecialistDirectoryRepository _repository;

  const GetLinkedSpecialistUseCase(this._authRepository, this._repository);

  Future<Result<Specialist?>> call() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.role != UserRole.patient) {
      return const Err(
          ValidationError('Operazione consentita solo al paziente.'));
    }
    return _repository.getLinkedSpecialist(user.taxCode);
  }
}
