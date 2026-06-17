import '../../core/error/result.dart';
import '../model/specialist.dart';
import '../model/specialization_type.dart';
import '../repository/specialist_directory_repository.dart';

/// Ricerca di discovery (RF13). Inoltra al repository i filtri opzionali e la
/// paginazione; esclusioni e dimensionamento dell'over-fetch stanno nel
/// ViewModel.
class SearchSpecialistsUseCase {
  final SpecialistDirectoryRepository _repository;

  const SearchSpecialistsUseCase(this._repository);

  Future<Result<List<Specialist>>> call({
    String? text,
    SpecializationType? specialization,
    String? city,
    required int page,
    int pageSize = 20,
  }) =>
      _repository.searchSpecialists(
        text: text,
        specialization: specialization,
        city: city,
        page: page,
        pageSize: pageSize,
      );
}
