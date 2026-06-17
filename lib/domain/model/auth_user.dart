import 'user_role.dart';

/// L'utente autenticato, risolto dalla sessione Supabase più la lookup su
/// `profilo_utente` (ADR-0009).
///
/// [taxCode] viaggia insieme al ruolo perché le letture a valle (profilo,
/// eliminazione account) indicizzano le righe `paziente`/`specialista` per
/// `CodiceFiscale`.
class AuthUser {
  /// UUID di `auth.users`.
  final String userId;
  final String email;
  final UserRole role;
  final String taxCode;

  const AuthUser({
    required this.userId,
    required this.email,
    required this.role,
    required this.taxCode,
  });
}
