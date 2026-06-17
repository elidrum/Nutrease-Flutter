import '../../domain/model/linked_patient.dart';
import '../dto/linked_patient_dto.dart';

/// Punto di traduzione per il DTO del paziente collegato: embed `paziente` IT→EN,
/// data di nascita ISO → [DateTime], e la guardia `Stato='Attivo'`.
extension LinkedPatientDtoMapper on LinkedPatientDto {
  /// Mappa su un [LinkedPatient] solo per un fascicolo attivo con embed paziente
  /// visibile; altrimenti restituisce `null`.
  ///
  /// Query e RLS restringono già a `Stato='Attivo'`, quindi questa è difesa in
  /// profondità: il mapper della lista scarta eventuali righe non attive o senza
  /// embed.
  LinkedPatient? toDomainIfActive() {
    if (stato != 'Attivo') return null;
    final taxCode = pazienteCodiceFiscale;
    if (taxCode == null) return null;
    return LinkedPatient(
      fascicoloId: idFascicolo,
      taxCode: taxCode,
      firstName: pazienteNome ?? '',
      surname: pazienteCognome ?? '',
      email: pazienteEmail,
      birthDate: pazienteDataNascita == null
          ? null
          : DateTime.parse(pazienteDataNascita!),
    );
  }
}
