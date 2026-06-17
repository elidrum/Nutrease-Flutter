import 'patient.dart';
import 'specialist.dart';
import 'user_role.dart';

/// Wrapper di lettura per il profilo dell'utente corrente.
///
/// Esattamente uno tra [patient]/[specialist] è non-null, in base a [role].
/// Costruito da `GetProfileUseCase` dall'utente auth più la riga specifica del
/// ruolo.
class UserProfile {
  final String userId;
  final UserRole role;
  final String taxCode;
  final Patient? patient;
  final Specialist? specialist;

  const UserProfile({
    required this.userId,
    required this.role,
    required this.taxCode,
    this.patient,
    this.specialist,
  });
}
