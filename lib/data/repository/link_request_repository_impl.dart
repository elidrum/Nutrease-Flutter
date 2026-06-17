import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../../domain/model/link_request_with_patient.dart';
import '../../domain/repository/link_request_repository.dart';
import '../dto/link_request_dto.dart';
import '../mapper/link_request_mapper.dart';
import 'supabase_error_mapper.dart';

/// Colonne selezionate per la inbox, più l'embed `paziente` per il nome (RF15).
const String _receivedColumns =
    'IdRichiesta, CodFiscalePaziente, CodFiscaleSpecialista, Stato, '
    'MessaggioRichiesta, DataRichiesta, DataRisposta, MotivazioneRifiuto, '
    'paziente(Nome, Cognome, DataNascita)';

/// [LinkRequestRepository] su Supabase (RF14–RF17). Le RLS limitano ogni riga
/// all'utente loggato; accept/reject sono semplici update (il trigger DB crea
/// fascicolo clinico + chat all'accettazione, ADR-0023).
class LinkRequestRepositoryImpl implements LinkRequestRepository {
  final SupabaseClient _client;

  const LinkRequestRepositoryImpl(this._client);

  @override
  Future<Result<void>> sendLinkRequest(String specialistTaxCode,
      {String? message}) async {
    try {
      final patientTaxCode = await _currentTaxCode();
      if (patientTaxCode == null) return const Err(AuthError());

      // Upsert sullo UNIQUE(CodFiscalePaziente, CodFiscaleSpecialista) così un
      // re-invio dopo un rifiuto riapre la richiesta (ADR-0023). I null espliciti
      // azzerano DataRisposta/MotivazioneRifiuto; Dart serializza i null, quindi
      // niente trappola encodeDefaults come nel client Kotlin.
      await _client.from('richiesta_collegamento').upsert(
        {
          'CodFiscalePaziente': patientTaxCode,
          'CodFiscaleSpecialista': specialistTaxCode,
          'Stato': 'In Attesa',
          'MessaggioRichiesta': message,
          'DataRisposta': null,
          'MotivazioneRifiuto': null,
        },
        onConflict: 'CodFiscalePaziente,CodFiscaleSpecialista',
      );
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<List<LinkRequestWithPatient>>> getReceivedLinkRequests() async {
    try {
      // Le RLS restituiscono solo le righe dove il chiamante è lo specialista;
      // filtro le pendenti, dalla più recente.
      final rows = await _client
          .from('richiesta_collegamento')
          .select(_receivedColumns)
          .eq('Stato', 'In Attesa')
          .order('DataRichiesta', ascending: false);

      final items = [
        for (final row in rows)
          LinkRequestWithPatientDto.fromJson(row).toDomain()
      ];
      return Ok(items);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> acceptLinkRequest(int requestId) async {
    try {
      await _client.from('richiesta_collegamento').update({
        'Stato': 'Accettata',
        'DataRisposta': _nowIso(),
      }).eq('IdRichiesta', requestId);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> rejectLinkRequest(int requestId, String reason) async {
    try {
      await _client.from('richiesta_collegamento').update({
        'Stato': 'Rifiutata',
        'DataRisposta': _nowIso(),
        'MotivazioneRifiuto': reason,
      }).eq('IdRichiesta', requestId);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<Set<String>>> getExcludedSpecialistTaxCodes() async {
    try {
      // Già collegati (fascicolo attivo) ∪ richiesta pendente. Le RLS limitano
      // entrambe al paziente loggato.
      final linked = await _client
          .from('fascicoloclinico')
          .select('CodFiscaleSpecialista')
          .eq('Stato', 'Attivo');
      final pending = await _client
          .from('richiesta_collegamento')
          .select('CodFiscaleSpecialista')
          .eq('Stato', 'In Attesa');

      final excluded = <String>{
        for (final row in linked) row['CodFiscaleSpecialista'] as String,
        for (final row in pending) row['CodFiscaleSpecialista'] as String,
      };
      return Ok(excluded);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  /// Il codice fiscale dell'utente loggato, via `profilo_utente` limitato dalle
  /// RLS (`profilo_utente_self` restituisce solo la riga del chiamante).
  Future<String?> _currentTaxCode() async {
    final rows = await _client
        .from('profilo_utente')
        .select('codice_fiscale')
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['codice_fiscale'] as String?;
  }

  static String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
