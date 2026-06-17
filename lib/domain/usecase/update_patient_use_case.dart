import '../../core/error/result.dart';
import '../model/patient.dart';
import '../repository/user_repository.dart';

/// Aggiorna i dati anagrafici del paziente (RF5).
class UpdatePatientUseCase {
  final UserRepository _userRepository;

  const UpdatePatientUseCase(this._userRepository);

  Future<Result<void>> call(Patient patient) =>
      _userRepository.updatePatient(patient);
}
