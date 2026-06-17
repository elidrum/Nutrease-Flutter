import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/meal.dart';
import '../repository/diary_repository.dart';

/// Registra un nuovo pasto multi-alimento (RF9); restituisce l'`IdPasto` creato.
class AddMealUseCase {
  final DiaryRepository _diaryRepository;

  const AddMealUseCase(this._diaryRepository);

  Future<Result<int>> call(Meal meal) async {
    if (meal.items.isEmpty) {
      return const Err(ValidationError('Aggiungi almeno un alimento.'));
    }
    if (meal.items.any((item) => item.amount <= 0)) {
      return const Err(
          ValidationError('Le quantità devono essere maggiori di zero.'));
    }
    return _diaryRepository.addMeal(meal);
  }
}
