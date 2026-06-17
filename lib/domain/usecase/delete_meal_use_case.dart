import '../../core/error/result.dart';
import '../repository/diary_repository.dart';

/// Elimina un pasto per id (RF12); le righe `alimento_pasto` cadono per FK.
class DeleteMealUseCase {
  final DiaryRepository _diaryRepository;

  const DeleteMealUseCase(this._diaryRepository);

  Future<Result<void>> call(int mealId) =>
      _diaryRepository.deleteMeal(mealId);
}
