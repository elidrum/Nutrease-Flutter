import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../repository/auth_repository.dart';

/// Invia l'email di reset per "password dimenticata".
class SendPasswordResetUseCase {
  final AuthRepository _authRepository;

  const SendPasswordResetUseCase(this._authRepository);

  Future<Result<void>> call(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return const Err(ValidationError('Inserisci un\'email valida'));
    }
    return _authRepository.sendPasswordReset(trimmed);
  }
}
