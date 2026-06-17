import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/password_policy.dart';
import '../repository/auth_repository.dart';

/// Completa il reset della password: verifica il codice di recupero a 8 cifre
/// inviato via email, imposta la nuova password, poi fa logout così l'utente
/// rientra da capo.
class ResetPasswordUseCase {
  final AuthRepository _authRepository;

  const ResetPasswordUseCase(this._authRepository);

  static final RegExp _eightDigits = RegExp(r'^\d{8}$');

  Future<Result<void>> call({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final trimmedCode = code.trim();
    if (!_eightDigits.hasMatch(trimmedCode)) {
      return const Err(ValidationError('Inserisci il codice a 8 cifre.'));
    }
    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) return Err(ValidationError(passwordError));

    final verify = await _authRepository.verifyRecoveryOtp(email, trimmedCode);
    if (verify is Err<void>) return verify;

    final change = await _authRepository.changePassword(newPassword);
    if (change is Err<void>) return change;

    return _authRepository.logout();
  }
}
