import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../domain/model/food.dart';
import '../../domain/repository/food_repository.dart';
import '../dto/food_dto.dart';
import '../mapper/food_mapper.dart';
import 'supabase_error_mapper.dart';

/// Colonne che il client MVP legge da `alimento` (senza `Alias`/`FonteDati`).
const String _foodColumns = 'IdAlimento, Nome, Categoria, LattosioP100g, '
    'SorbitoloP100g, GlutineP100g, CaloriePer100g, ConversioniUnitaMisura';

/// Top-level così [compute] può girarlo in un isolate: costruire 1.388 [Food]
/// (col parsing delle conversioni jsonb) fuori dal thread della UI.
List<Food> parseFoods(List<Map<String, dynamic>> rows) =>
    [for (final row in rows) FoodDto.fromJson(row).toDomain()];

/// [FoodRepository] su Supabase con cache in memoria del dataset.
///
/// Registrato come singleton (equivalente ADR-0029): l'intera tabella `alimento`
/// viene letta una volta, parsata via [compute], poi servita dalla memoria. Le
/// prime chiamate concorrenti condividono lo stesso caricamento tramite la
/// guardia [_inflight] (single-flight sul fetch).
class FoodRepositoryImpl implements FoodRepository {
  final SupabaseClient _client;

  FoodRepositoryImpl(this._client);

  List<Food>? _cache;
  Future<List<Food>>? _inflight;

  @override
  Future<Result<List<Food>>> getAllFoods() async {
    final cached = _cache;
    if (cached != null) return Ok(cached);
    try {
      final foods = await (_inflight ??= _loadAll());
      return Ok(foods);
    } catch (e) {
      return Err(mapSupabaseError(e));
    } finally {
      // Sempre azzerato: un successo lo serve _cache, un fallimento deve riprovare.
      _inflight = null;
    }
  }

  Future<List<Food>> _loadAll() async {
    // Pagino oltre il limite di righe di default di PostgREST (dataset di 1.388 righe).
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await _client
          .from('alimento')
          .select(_foodColumns)
          .order('IdAlimento', ascending: true)
          .range(from, from + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }

    final foods = await compute(parseFoods, rows);
    _cache = foods;
    return foods;
  }
}
