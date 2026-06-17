import '../../core/error/result.dart';
import '../repository/auth_repository.dart';

/// Chiude la sessione (RF4).
class LogoutUseCase {
  final AuthRepository _authRepository;

  const LogoutUseCase(this._authRepository);

  Future<Result<void>> call() => _authRepository.logout();
}
