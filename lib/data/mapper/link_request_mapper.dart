import '../../domain/model/link_request.dart';
import '../../domain/model/link_request_status.dart';
import '../../domain/model/link_request_with_patient.dart';
import '../dto/link_request_dto.dart';

/// Unico punto di traduzione per i DTO `richiesta_collegamento`: `Stato` IT↔enum,
/// timestamp ISO↔[DateTime], messaggio/motivazione passati invariati.
extension LinkRequestDtoMapper on LinkRequestDto {
  LinkRequest toDomain() => LinkRequest(
        id: idRichiesta,
        patientTaxCode: codFiscalePaziente,
        specialistTaxCode: codFiscaleSpecialista,
        status: LinkRequestStatus.fromDbLabel(stato),
        message: messaggioRichiesta,
        createdAt: DateTime.parse(dataRichiesta),
        respondedAt: dataRisposta == null ? null : DateTime.parse(dataRisposta!),
        rejectionReason: motivazioneRifiuto,
      );
}

extension LinkRequestWithPatientDtoMapper on LinkRequestWithPatientDto {
  LinkRequestWithPatient toDomain() => LinkRequestWithPatient(
        request: request.toDomain(),
        patientFirstName: pazienteNome,
        patientSurname: pazienteCognome,
        patientBirthDate: pazienteDataNascita == null
            ? null
            : DateTime.parse(pazienteDataNascita!),
      );
}
