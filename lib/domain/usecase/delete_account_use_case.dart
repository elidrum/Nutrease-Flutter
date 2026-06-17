import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../repository/auth_repository.dart';

/// Elimina l'account (RF7): conferma la password (re-auth), rimuove le righe di
/// profilo server-side, poi fa logout. Codice fiscale e ruolo si leggono
/// dall'utente corrente, mai passati dalla UI.
class DeleteAccountUseCase {
  final AuthRepository _authRepository;

  const DeleteAccountUseCase(this._authRepository);

  Future<Result<void>> call(String password) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return const Err(AuthError());

    final reauth = await _authRepository.reauthenticate(user.email, password);
    if (reauth is Err<void>) return reauth;

    final deleted = await _authRepository.deleteAccount();
    if (deleted is Err<void>) return deleted;

    return _authRepository.logout();
  }
}
