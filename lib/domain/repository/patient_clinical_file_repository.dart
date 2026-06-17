import '../../core/error/result.dart';

/// Accesso al fascicolo clinico del paziente (`fascicoloclinico`).
///
/// Salvare un pasto richiede l'id del fascicolo attivo; le RLS limitano già la
/// query al paziente loggato.
abstract interface class PatientClinicalFileRepository {
  /// L'`IdFascicolo` del fascicolo `Stato='Attivo'` del paziente, o un errore
  /// esplicito quando non esiste (prerequisito DB, come in Android).
  Future<Result<int>> getActiveFascicoloId();
}
