import 'link_request.dart';

/// Una [LinkRequest] ricevuta, arricchita col nome del paziente richiedente (e,
/// quando disponibile, la data di nascita) per l'inbox dello specialista (RF15).
///
/// Il nome arriva dall'embed PostgREST `paziente(...)`; [patientBirthDate] è
/// opzionale perché l'inbox la usa solo per mostrare l'età del paziente.
class LinkRequestWithPatient {
  final LinkRequest request;
  final String patientFirstName;
  final String patientSurname;
  final DateTime? patientBirthDate;

  const LinkRequestWithPatient({
    required this.request,
    required this.patientFirstName,
    required this.patientSurname,
    this.patientBirthDate,
  });

  /// "Nome Cognome" per la visualizzazione.
  String get patientFullName => '$patientFirstName $patientSurname';
}
