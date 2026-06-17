import '../../core/error/result.dart';
import '../model/food.dart';

/// Accesso in lettura al dataset `alimento`.
///
/// L'implementazione mette in cache in memoria l'intero dataset dopo il primo
/// fetch (singleton + guardia single-flight): la ricerca è client-side
/// (`FoodSearch`), quindi le chiamate ripetute non devono toccare la rete.
abstract interface class FoodRepository {
  Future<Result<List<Food>>> getAllFoods();
}
