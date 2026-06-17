// Nascondo l'`AuthUser` dell'SDK per evitare il conflitto col model di dominio.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../../domain/model/auth_user.dart';
import '../../domain/model/register_data.dart';
import '../../domain/model/user_role.dart';
import '../../domain/repository/auth_repository.dart';
import 'supabase_error_mapper.dart';

/// [AuthRepository] su Supabase.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  const AuthRepositoryImpl(this._client);

  GoTrueClient get _auth => _client.auth;

  @override
  Future<Result<AuthUser>> login(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
      final user = await getCurrentUser();
      // Nessuna riga di profilo → account in stato incoerente; resto generico.
      if (user == null) return const Err(AuthError());
      return Ok(user);
    } on AuthException {
      // Generico su ogni fallimento di auth: non rivelare mai se l'email esiste
      // o se la password era sbagliata (anti user-enumeration).
      return const Err(AuthError());
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> register(RegisterData data) async {
    try {
      // Le righe di profilo le crea server-side il trigger `crea_profilo_da_auth`
      // a partire da questi metadati (ADR-0015).
      await _auth.signUp(
        email: data.email,
        password: data.password,
        data: data.toAuthMetadata(),
      );
      return const Ok(null);
    } on AuthException catch (e) {
      // I fallimenti del trigger emergono come 5xx opachi; mostro un messaggio
      // generico. L'email duplicata è l'unico caso da segnalare esplicitamente.
      final isDuplicate = e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already');
      return Err(ValidationError(isDuplicate
          ? 'Esiste già un account con questa email.'
          : 'Registrazione non riuscita. Verifica i dati e riprova.'));
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _auth.signOut();
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      // `Supabase.initialize` (atteso in main) ripristina l'eventuale sessione
      // persistita prima di costruire l'albero, così `currentUser` è leggibile
      // qui (ADR-0021).
      final user = _auth.currentUser;
      if (user == null) return null;

      final row = await _client
          .from('profilo_utente')
          .select('ruolo, codice_fiscale')
          .eq('auth_uid', user.id)
          .maybeSingle();
      if (row == null) return null;

      return AuthUser(
        userId: user.id,
        email: user.email ?? '',
        role: UserRole.fromDb(row['ruolo'] as String),
        taxCode: row['codice_fiscale'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<void>> reauthenticate(String email, String password) async {
    try {
      // Rifare il sign-in verifica la password corrente; una sbagliata solleva.
      await _auth.signInWithPassword(email: email, password: password);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> changePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      // RPC server-side (`delete_own_account`, SECURITY DEFINER — ADR-0024): il
      // client non ha policy DELETE su `paziente`/`specialista` né accesso a
      // `auth.users`, quindi una delete lato client verrebbe filtrata dalle RLS e
      // lascerebbe l'account in limbo. La RPC rimuove le righe di dominio E
      // l'utente auth in modo atomico, come owner della tabella. Restituisce uno
      // tra: 'deleted' | 'has_linked_patients' | 'not_authenticated'.
      final outcome = await _client.rpc<dynamic>('delete_own_account');
      return switch (outcome) {
        'deleted' => const Ok(null),
        'has_linked_patients' => const Err(ValidationError(
            'Hai ancora pazienti collegati: non puoi eliminare l\'account.')),
        'not_authenticated' => const Err(AuthError()),
        _ => const Err(UnknownError()),
      };
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> verifyRecoveryOtp(String email, String code) async {
    try {
      await _auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
      return const Ok(null);
    } on AuthException {
      // Codice errato o scaduto — messaggio specifico, non quello generico del login.
      return const Err(ValidationError('Codice non valido o scaduto.'));
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }
}
