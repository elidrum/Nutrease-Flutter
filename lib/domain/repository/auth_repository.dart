import '../../core/error/result.dart';
import '../model/auth_user.dart';
import '../model/register_data.dart';

/// Confine dell'autenticazione (Supabase Auth). Implementato nel data layer; il
/// dominio vede solo questa interfaccia (ADR-0007).
abstract interface class AuthRepository {
  /// Effettua l'accesso e risolve il ruolo. I fallimenti mappano su un
  /// [AuthError] **generico** (anti user-enumeration).
  Future<Result<AuthUser>> login(String email, String password);

  /// Registra via `signUp` con i metadati per il trigger. La creazione del
  /// profilo avviene server-side (ADR-0015).
  Future<Result<void>> register(RegisterData data);

  Future<Result<void>> logout();

  /// L'utente corrente dopo l'init della sessione, o `null` se non loggato.
  Future<AuthUser?> getCurrentUser();

  /// Riverifica le credenziali date prima di un'azione sensibile (RF6/RF7).
  Future<Result<void>> reauthenticate(String email, String password);

  /// Aggiorna la password dell'utente corrente (`updateUser`).
  Future<Result<void>> changePassword(String newPassword);

  /// Elimina server-side le righe di profilo dell'utente corrente (RF7). Non fa
  /// logout — ci pensa dopo il chiamante (`DeleteAccountUseCase`).
  Future<Result<void>> deleteAccount();

  /// Invia l'email di reset password contenente il codice OTP di recupero.
  Future<Result<void>> sendPasswordReset(String email);

  /// Verifica l'OTP di recupero [code] inviato a [email] e apre una sessione di
  /// recupero di breve durata, così la nuova password si può impostare via
  /// [changePassword].
  Future<Result<void>> verifyRecoveryOtp(String email, String code);
}
