import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/age_policy.dart';
import '../model/password_policy.dart';
import '../model/register_data.dart';
import '../repository/auth_repository.dart';

/// Registra un paziente o uno specialista (RF1/RF2).
///
/// Valida la password (e, per i pazienti, la data di nascita) **prima** di
/// arrivare al repository: i fallimenti del trigger emergono come 500 opachi da
/// Auth, quindi intercettarli a monte dà un messaggio chiaro in italiano
/// (ADR-0015/0026).
class RegisterUseCase {
  final AuthRepository _authRepository;

  const RegisterUseCase(this._authRepository);

  Future<Result<void>> call(RegisterData data) async {
    final passwordError = PasswordPolicy.validate(data.password);
    if (passwordError != null) return Err(ValidationError(passwordError));

    if (data is PatientRegisterData &&
        !AgePolicy.isValidBirthDate(data.birthDate)) {
      return const Err(ValidationError(
        'Devi avere almeno ${AgePolicy.minAge} anni per registrarti',
      ));
    }

    return _authRepository.register(data);
  }
}
