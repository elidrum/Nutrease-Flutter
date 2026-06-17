import '../../core/error/result.dart';
import '../model/user_profile.dart';
import '../repository/user_repository.dart';

/// Carica il profilo dell'utente corrente (RF5).
class GetProfileUseCase {
  final UserRepository _userRepository;

  const GetProfileUseCase(this._userRepository);

  Future<Result<UserProfile>> call() => _userRepository.getProfile();
}
