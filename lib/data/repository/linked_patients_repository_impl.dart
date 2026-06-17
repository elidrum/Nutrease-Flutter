import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../domain/model/linked_patient.dart';
import '../../domain/repository/linked_patients_repository.dart';
import '../dto/linked_patient_dto.dart';
import '../mapper/linked_patient_mapper.dart';
import 'supabase_error_mapper.dart';

/// Colonne selezionate per la lista pazienti collegati, più l'embed `paziente`
/// per nome ed età (RF18).
const String _linkedColumns =
    'IdFascicolo, Stato, paziente(CodiceFiscale, Nome, Cognome, Email, DataNascita)';

/// [LinkedPatientsRepository] su Supabase (RF18).
///
/// Le RLS limitano `fascicoloclinico` allo specialista loggato (policy
/// `fascicolo_specialista`), quindi la query filtra solo i fascicoli attivi —
/// niente match dello specialista lato client, lo stesso schema della lettura
/// delle esclusioni. Niente nuovo repository per il diario: la vista read-only
/// riusa `DiaryRepository`/`SymptomRepository` (ADR-0016).
class LinkedPatientsRepositoryImpl implements LinkedPatientsRepository {
  final SupabaseClient _client;

  const LinkedPatientsRepositoryImpl(this._client);

  @override
  Future<Result<List<LinkedPatient>>> getLinkedPatients() async {
    try {
      final rows = await _client
          .from('fascicoloclinico')
          .select(_linkedColumns)
          .eq('Stato', 'Attivo');

      final patients = <LinkedPatient>[
        // Elemento null-aware: scarta eventuali righe non attive / senza embed.
        for (final row in rows) ?LinkedPatientDto.fromJson(row).toDomainIfActive(),
      ]..sort((a, b) =>
          a.surname.toLowerCase().compareTo(b.surname.toLowerCase()));

      return Ok(patients);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }
}
