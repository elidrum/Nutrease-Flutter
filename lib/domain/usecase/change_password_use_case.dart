import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/password_policy.dart';
import '../repository/auth_repository.dart';

/// Cambia la password (RF6): valida la nuova, riverifica quella corrente
/// (re-auth), poi aggiorna l'utente (ADR-0021).
class ChangePasswordUseCase {
  final AuthRepository _authRepository;

  const ChangePasswordUseCase(this._authRepository);

  Future<Result<void>> call(String currentPassword, String newPassword) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return const Err(AuthError());

    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) return Err(ValidationError(passwordError));

    final reauth =
        await _authRepository.reauthenticate(user.email, currentPassword);
    if (reauth is Err<void>) return reauth;

    return _authRepository.changePassword(newPassword);
  }
}
