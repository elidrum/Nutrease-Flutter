import '../../core/error/result.dart';
import '../model/meal.dart';
import '../repository/diary_repository.dart';

/// Carica un singolo pasto con le sue righe alimento, per pre-compilare il form
/// di modifica (ADR-0013).
class GetMealUseCase {
  final DiaryRepository _diaryRepository;

  const GetMealUseCase(this._diaryRepository);

  Future<Result<Meal>> call(int mealId) => _diaryRepository.getMeal(mealId);
}
