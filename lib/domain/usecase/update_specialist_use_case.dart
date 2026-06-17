import '../../core/error/result.dart';
import '../model/specialist.dart';
import '../repository/user_repository.dart';

/// Aggiorna i dati professionali dello specialista (RF5).
class UpdateSpecialistUseCase {
  final UserRepository _userRepository;

  const UpdateSpecialistUseCase(this._userRepository);

  Future<Result<void>> call(Specialist specialist) =>
      _userRepository.updateSpecialist(specialist);
}
