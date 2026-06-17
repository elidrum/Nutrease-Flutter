import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../domain/model/symptom.dart';
import '../../domain/repository/symptom_repository.dart';
import '../dto/symptom_dto.dart';
import '../local/diary_cache_dao.dart';
import '../mapper/symptom_mapper.dart';
import 'cache_fallback.dart';
import 'supabase_error_mapper.dart';

/// [SymptomRepository] su Supabase per `sintomo` (RF10/RF11/RF12).
///
/// Le scritture inviano solo l'etichetta di tipo + l'intensità canonica; il primo
/// INSERT di una data crea da sé `diariogiornaliero` (`crea_diario_se_mancante`).
/// Le RLS limitano ogni riga al paziente loggato.
class SymptomRepositoryImpl implements SymptomRepository {
  final SupabaseClient _client;
  final DiaryCacheDao _cache;

  SymptomRepositoryImpl(this._client, this._cache);

  @override
  Future<Result<int>> addSymptom(Symptom symptom) async {
    try {
      final inserted = await _client
          .from('sintomo')
          .insert(symptom.toDto().toJson())
          .select('IdSintomo')
          .single();
      return Ok(inserted['IdSintomo'] as int);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> updateSymptom(Symptom symptom) async {
    try {
      final dto = symptom.toDto();
      await _client.from('sintomo').update({
        'Data': dto.data,
        'Ora': dto.ora,
        'Descrizione': dto.descrizione,
        'Intensita': dto.intensita,
      }).eq('IdSintomo', symptom.id!);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> deleteSymptom(int id) async {
    try {
      await _client.from('sintomo').delete().eq('IdSintomo', id);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<Symptom>> getSymptom(int id) async {
    try {
      final row =
          await _client.from('sintomo').select().eq('IdSintomo', id).single();
      return Ok(symptomFromDto(SymptomDto.fromJson(row)));
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<List<Symptom>>> getSymptomsForDate(
      int fascicoloId, DateTime date) async {
    final dateKey = date.toIso8601String().split('T').first;
    try {
      final rows = await _client
          .from('sintomo')
          .select()
          .eq('IdFascicolo', fascicoloId)
          .eq('Data', dateKey)
          .order('Ora', ascending: true);
      final symptoms = [
        for (final row in rows) symptomFromDto(SymptomDto.fromJson(row))
      ];
      // Scrittura cache-aside: best-effort, non rompe mai il percorso online.
      await runCacheOp(() => _cache.replaceSymptoms(fascicoloId, date, symptoms));
      return Ok(symptoms);
    } catch (e) {
      // Rete/DB ko: ripiego sul giorno in cache (RF11). Distinguo "giornata mai
      // sincronizzata" (→ errore di rete) da "giornata sincronizzata e vuota"
      // (→ Ok lista vuota).
      final synced =
          await runCacheOp(() => _cache.isDaySynced(fascicoloId, date)) ?? false;
      if (synced) {
        final cached =
            await runCacheOp(() => _cache.getSymptoms(fascicoloId, date));
        return Ok(cached ?? const <Symptom>[]);
      }
      return Err(mapSupabaseError(e));
    }
  }
}
