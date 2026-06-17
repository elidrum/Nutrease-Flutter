import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../domain/model/specialist.dart';
import '../../domain/model/specialization_type.dart';
import '../../domain/repository/specialist_directory_repository.dart';
import '../dto/fascicolo_with_specialist_dto.dart';
import '../dto/specialist_dto.dart';
import '../mapper/specialist_mapper.dart';
import 'supabase_error_mapper.dart';

/// Le colonne `specialista` modellate dallo [SpecialistDto] Flutter — manca
/// `Verificato` (il client non modella mai la verifica; la visibilità la
/// impongono già le RLS, ADR-0028).
const String _specialistColumns =
    'CodiceFiscale, Nome, Cognome, Email, PartitaIVA, Specializzazione, Citta, Info';

/// [SpecialistDirectoryRepository] su Supabase. Le RLS restringono ogni lettura
/// agli specialisti verificati/visibili (ADR-0028) e limitano il fascicolo al
/// paziente — niente logica "verificato" lato client.
class SpecialistDirectoryRepositoryImpl
    implements SpecialistDirectoryRepository {
  final SupabaseClient _client;

  const SpecialistDirectoryRepositoryImpl(this._client);

  @override
  Future<Result<List<Specialist>>> searchSpecialists({
    String? text,
    SpecializationType? specialization,
    String? city,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('specialista').select(_specialistColumns);

      final trimmedText = text?.trim();
      if (trimmedText != null && trimmedText.isNotEmpty) {
        // Match su nome OPPURE cognome (ilike server-side sulle colonne indicizzate).
        query = query
            .or('Nome.ilike.%$trimmedText%,Cognome.ilike.%$trimmedText%');
      }
      if (specialization != null) {
        query = query.eq('Specializzazione', specialization.dbLabel);
      }
      final trimmedCity = city?.trim();
      if (trimmedCity != null && trimmedCity.isNotEmpty) {
        query = query.ilike('Citta', '%$trimmedCity%');
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;
      // Ordine stabile così la paginazione non restituisce righe sovrapposte/saltate.
      final rows = await query
          .order('Cognome', ascending: true)
          .order('Nome', ascending: true)
          .order('CodiceFiscale', ascending: true)
          .range(from, to);

      final specialists = [
        for (final row in rows) SpecialistDto.fromJson(row).toDomain()
      ];
      return Ok(specialists);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<Specialist?>> getLinkedSpecialist(String patientTaxCode) async {
    try {
      final rows = await _client
          .from('fascicoloclinico')
          .select('IdFascicolo, specialista($_specialistColumns)')
          .eq('CodFiscalePaziente', patientTaxCode)
          .eq('Stato', 'Attivo')
          .limit(1);

      if (rows.isEmpty) return const Ok(null);
      final dto = FascicoloWithSpecialistDto.fromJson(rows.first);
      // Embed null (specialista de-verificato e nascosto dalle RLS) → "nessuno", non errore.
      return Ok(dto.specialist?.toDomain());
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }
}
