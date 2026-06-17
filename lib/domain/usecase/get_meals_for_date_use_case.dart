import '../../core/error/result.dart';
import '../model/meal.dart';
import '../repository/diary_repository.dart';

/// Carica i pasti di una data per un fascicolo clinico (RF11).
class GetMealsForDateUseCase {
  final DiaryRepository _diaryRepository;

  const GetMealsForDateUseCase(this._diaryRepository);

  Future<Result<List<Meal>>> call(int fascicoloId, DateTime date) =>
      _diaryRepository.getMealsForDate(fascicoloId, date);
}
