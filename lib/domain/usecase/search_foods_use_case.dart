import '../../core/error/result.dart';
import '../model/food.dart';
import '../model/food_search.dart';
import '../repository/food_repository.dart';

/// Cerca nel dataset `alimento` in cache, lato client (RF8, ADR-0029).
///
/// Carica il dataset via il repository (con cache) e lo ordina con l'algoritmo
/// puro [FoodSearch]. Una query vuota cortocircuita a lista vuota.
class SearchFoodsUseCase {
  final FoodRepository _foodRepository;

  const SearchFoodsUseCase(this._foodRepository);

  Future<Result<List<Food>>> call(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return const Ok([]);
    final result = await _foodRepository.getAllFoods();
    return result.fold(
      ok: (foods) => Ok(FoodSearch.search(foods, query, limit: limit)),
      err: Err.new,
    );
  }
}
