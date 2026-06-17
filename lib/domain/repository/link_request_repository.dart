import '../../core/error/result.dart';
import '../model/link_request_with_patient.dart';

/// Richieste di collegamento tra pazienti e specialisti (RF14–RF17).
abstract interface class LinkRequestRepository {
  /// Invia (o re-invia) una richiesta a [specialistTaxCode] con [message]
  /// opzionale. È un **upsert** sullo `UNIQUE(CodFiscalePaziente,
  /// CodFiscaleSpecialista)`: un re-invio dopo un rifiuto riapre la richiesta
  /// (torna `In Attesa`, azzerando i campi di risposta) invece di sbattere sul
  /// vincolo (ADR-0023).
  Future<Result<void>> sendLinkRequest(String specialistTaxCode,
      {String? message});

  /// Le richieste pendenti (`In Attesa`) indirizzate allo specialista corrente,
  /// dalla più recente, ciascuna col nome del paziente richiedente (RF15).
  Future<Result<List<LinkRequestWithPatient>>> getReceivedLinkRequests();

  /// Accetta una richiesta (`Stato='Accettata'`). Un trigger DB crea poi il
  /// fascicolo clinico (e la chat); il client non scrive nessuno dei due (RF16).
  Future<Result<void>> acceptLinkRequest(int requestId);

  /// Rifiuta una richiesta con [reason] obbligatoria (`Stato='Rifiutata'`, RF17).
  Future<Result<void>> rejectLinkRequest(int requestId, String reason);

  /// Codici fiscali da escludere dalla discovery del paziente: specialisti già
  /// collegati (fascicolo attivo) o con una richiesta pendente.
  Future<Result<Set<String>>> getExcludedSpecialistTaxCodes();
}
