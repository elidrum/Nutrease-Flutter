import '../../core/error/result.dart';
import '../model/auth_user.dart';
import '../repository/auth_repository.dart';

/// Effettua l'accesso e restituisce l'utente risolto (RF3).
class LoginUseCase {
  final AuthRepository _authRepository;

  const LoginUseCase(this._authRepository);

  Future<Result<AuthUser>> call(String email, String password) =>
      _authRepository.login(email, password);
}
