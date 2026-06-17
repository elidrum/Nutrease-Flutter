import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/meal.dart';
import '../repository/diary_repository.dart';

/// Aggiorna un pasto esistente, sostituendone le righe alimento (RF9 / modifica
/// ADR-0013).
class UpdateMealUseCase {
  final DiaryRepository _diaryRepository;

  const UpdateMealUseCase(this._diaryRepository);

  Future<Result<void>> call(Meal meal) async {
    if (meal.id == null) {
      return const Err(ValidationError('Pasto senza ID: impossibile aggiornare.'));
    }
    if (meal.items.isEmpty) {
      return const Err(ValidationError('Aggiungi almeno un alimento.'));
    }
    if (meal.items.any((item) => item.amount <= 0)) {
      return const Err(
          ValidationError('Le quantità devono essere maggiori di zero.'));
    }
    return _diaryRepository.updateMeal(meal);
  }
}
