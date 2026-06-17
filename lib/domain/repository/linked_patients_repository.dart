import '../../core/error/result.dart';
import '../model/linked_patient.dart';

/// I pazienti collegati allo specialista loggato (fascicoli clinici attivi, RF18).
///
/// L'**unico** repository nuovo dello sprint 6: la vista read-only del diario
/// riusa `DiaryRepository`/`SymptomRepository` parametrici sul `fascicoloId`
/// (ADR-0016), quindi non serve un nuovo repository per il diario.
abstract interface class LinkedPatientsRepository {
  /// I pazienti con un `fascicoloclinico` attivo per lo specialista corrente.
  /// Le RLS limitano le righe allo specialista loggato.
  Future<Result<List<LinkedPatient>>> getLinkedPatients();
}
