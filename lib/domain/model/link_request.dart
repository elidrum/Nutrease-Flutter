import 'link_request_status.dart';

/// Una richiesta di collegamento da un paziente a uno specialista
/// (`richiesta_collegamento`).
///
/// Modello di dominio puro: i timestamp sono `DateTime`, lo stato è un enum. Il
/// data layer traduce da/verso le colonne DB italiane nel mapper.
class LinkRequest {
  final int id;
  final String patientTaxCode;
  final String specialistTaxCode;
  final LinkRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? rejectionReason;

  const LinkRequest({
    required this.id,
    required this.patientTaxCode,
    required this.specialistTaxCode,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    this.rejectionReason,
  });
}
