import '../../core/error/result.dart';
import '../model/specialist.dart';
import '../model/specialization_type.dart';

/// Discovery degli specialisti (RF13) e lo specialista attualmente collegato al
/// paziente.
///
/// Vengono restituiti solo gli specialisti **verificati/visibili**: lo impongono
/// le RLS (ADR-0028), mai la logica lato client.
abstract interface class SpecialistDirectoryRepository {
  /// Una pagina di specialisti che soddisfano i filtri opzionali.
  ///
  /// Tutti i filtri sono opzionali: [text] fa un `ilike` su nome/cognome,
  /// [specialization] `null` significa "tutte", [city] fa un `ilike`. [page] è
  /// 0-based e vengono richieste [pageSize] righe (il chiamante sovra-carica per
  /// lasciare spazio alle esclusioni lato client). La lista restituita è la
  /// pagina **grezza** (le esclusioni le applica il chiamante).
  Future<Result<List<Specialist>>> searchSpecialists({
    String? text,
    SpecializationType? specialization,
    String? city,
    required int page,
    int pageSize = 20,
  });

  /// Lo specialista del fascicolo `Stato='Attivo'` del paziente, o `null` quando
  /// il paziente non è collegato. Lo `UNIQUE(CodFiscalePaziente)` sul fascicolo
  /// garantisce al più uno. Uno specialista de-verificato e nascosto dalle RLS
  /// rilegge come `null` (trattato come "nessuno", non come errore).
  Future<Result<Specialist?>> getLinkedSpecialist(String patientTaxCode);
}
