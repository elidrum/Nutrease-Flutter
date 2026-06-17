import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../../domain/repository/patient_clinical_file_repository.dart';
import '../dto/fascicolo_id_dto.dart';
import 'supabase_error_mapper.dart';

/// [PatientClinicalFileRepository] su Supabase. Le RLS limitano già
/// `fascicoloclinico` al paziente loggato, quindi non serve filtrare per CF.
class PatientClinicalFileRepositoryImpl
    implements PatientClinicalFileRepository {
  final SupabaseClient _client;

  const PatientClinicalFileRepositoryImpl(this._client);

  @override
  Future<Result<int>> getActiveFascicoloId() async {
    try {
      final rows = await _client
          .from('fascicoloclinico')
          .select('IdFascicolo')
          .eq('Stato', 'Attivo')
          .limit(1);
      if (rows.isEmpty) {
        // Prerequisito DB, stesso messaggio esplicito di Android.
        return const Err(NotFoundError(
            'Nessun fascicolo attivo: collegati a uno specialista per '
            'iniziare il diario.'));
      }
      return Ok(FascicoloIdDto.fromJson(rows.first).idFascicolo);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }
}
