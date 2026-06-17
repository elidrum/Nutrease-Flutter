import '../../core/error/result.dart';
import '../model/patient.dart';
import '../model/specialist.dart';
import '../model/user_profile.dart';

/// Confine di lettura/aggiornamento del profilo. La creazione è server-side via
/// il trigger di auth (ADR-0015), quindi non esistono `createPatient`/
/// `createSpecialist`.
abstract interface class UserRepository {
  /// Carica il profilo completo dell'utente corrente (inclusa la riga di ruolo).
  Future<Result<UserProfile>> getProfile();

  /// PATCH parziale dei campi anagrafici modificabili del paziente (mai l'email).
  Future<Result<void>> updatePatient(Patient patient);

  /// PATCH parziale dei campi professionali modificabili dello specialista.
  Future<Result<void>> updateSpecialist(Specialist specialist);
}
