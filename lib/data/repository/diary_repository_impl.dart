import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../domain/model/meal.dart';
import '../../domain/repository/diary_repository.dart';
import '../dto/meal_dto.dart';
import '../dto/meal_food_dto.dart';
import '../local/diary_cache_dao.dart';
import '../mapper/meal_mapper.dart';
import 'cache_fallback.dart';
import 'supabase_error_mapper.dart';

/// Colonne alimento lette tramite l'embed `alimento_pasto → alimento`.
const String _mealEmbed = '*, alimento_pasto(*, alimento(IdAlimento, Nome, '
    'Categoria, LattosioP100g, SorbitoloP100g, GlutineP100g, CaloriePer100g, '
    'ConversioniUnitaMisura))';

/// Implementazione di [DiaryRepository] su Supabase/PostgREST (tabelle `pasto`
/// e `alimento_pasto`). Due fatti delegati al DB e quindi assenti qui: la riga
/// di `diariogiornaliero` la crea un trigger al primo inserimento del giorno
/// (`crea_diario_se_mancante`), e i nutrienti per riga li calcola il trigger
/// `calcola_nutrienti_pasto` (ADR-0010) — il client invia solo i grammi.
class DiaryRepositoryImpl implements DiaryRepository {
  final SupabaseClient _client;
  final DiaryCacheDao _cache;

  DiaryRepositoryImpl(this._client, this._cache);

  @override
  Future<Result<int>> addMeal(Meal meal) async {
    try {
      final inserted = await _client
          .from('pasto')
          .insert(meal.toDto().toJson())
          .select('IdPasto')
          .single();
      final mealId = inserted['IdPasto'] as int;

      try {
        await _client
            .from('alimento_pasto')
            .insert([for (final item in meal.items) item.toDto().toInsertJson(mealId)]);
      } catch (e) {
        // Rollback logico: niente pasto salvato a metà. Cancellare la testata
        // fa cadere anche le righe già inserite (FK ON DELETE CASCADE).
        await _deleteMealRow(mealId);
        return Err(mapSupabaseError(e));
      }
      return Ok(mealId);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> updateMeal(Meal meal) async {
    try {
      final mealId = meal.id!;
      final dto = meal.toDto();
      await _client.from('pasto').update({
        'Data': dto.data,
        'Ora': dto.ora,
        'Tipologia': dto.tipologia,
      }).eq('IdPasto', mealId);

      // Sostituisco le righe in blocco così il trigger ricalcola tutti i *Calc.
      await _client.from('alimento_pasto').delete().eq('IdPasto', mealId);
      await _client
          .from('alimento_pasto')
          .insert([for (final item in meal.items) item.toDto().toInsertJson(mealId)]);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<Meal>> getMeal(int mealId) async {
    try {
      final row = await _client
          .from('pasto')
          .select(_mealEmbed)
          .eq('IdPasto', mealId)
          .single();
      return Ok(_mealFromRow(row));
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<List<Meal>>> getMealsForDate(
      int fascicoloId, DateTime date) async {
    final dateKey = date.toIso8601String().split('T').first;
    try {
      final rows = await _client
          .from('pasto')
          .select(_mealEmbed)
          .eq('IdFascicolo', fascicoloId)
          .eq('Data', dateKey)
          .order('Ora', ascending: true);
      final meals = [for (final row in rows) _mealFromRow(row)];
      // Scrittura cache-aside: best-effort, non rompe mai il percorso online.
      await runCacheOp(() => _cache.replaceMeals(fascicoloId, date, meals));
      return Ok(meals);
    } catch (e) {
      // Rete/DB ko: ripiego sul giorno in cache (RF11). Distinguo "giornata mai
      // sincronizzata" (→ errore di rete) da "giornata sincronizzata e vuota"
      // (→ Ok lista vuota).
      final synced =
          await runCacheOp(() => _cache.isDaySynced(fascicoloId, date)) ?? false;
      if (synced) {
        final cached =
            await runCacheOp(() => _cache.getMeals(fascicoloId, date));
        return Ok(cached ?? const <Meal>[]);
      }
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> deleteMeal(int mealId) async {
    try {
      // Le righe `alimento_pasto` cadono per FK ON DELETE CASCADE (RF12).
      await _client.from('pasto').delete().eq('IdPasto', mealId);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  /// Costruisce un [Meal] da una riga `pasto` con il suo `alimento_pasto` embeddato.
  Meal _mealFromRow(Map<String, dynamic> row) {
    final items = [
      for (final itemJson in (row['alimento_pasto'] as List? ?? const []))
        MealFoodDto.fromJson(itemJson as Map<String, dynamic>)
    ];
    return mealFromDto(MealDto.fromJson(row), items);
  }

  /// Pulizia best-effort di una testata `pasto` orfana (rollback di addMeal):
  /// ingoia il proprio errore così quello riportato resta l'originale.
  Future<void> _deleteMealRow(int mealId) async {
    try {
      await _client.from('pasto').delete().eq('IdPasto', mealId);
    } catch (_) {}
  }
}
