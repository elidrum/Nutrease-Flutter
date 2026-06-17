import '../../core/error/result.dart';
import '../repository/link_request_repository.dart';

/// Codici fiscali da nascondere nella discovery (RF13): specialisti già
/// collegati o con una richiesta pendente. Il ViewModel usa il set sia per
/// filtrare i risultati sia per dimensionare l'over-fetch. Incapsula il
/// repository così il VM non lo tocca mai direttamente (flusso obbligato).
class GetExcludedSpecialistTaxCodesUseCase {
  final LinkRequestRepository _repository;

  const GetExcludedSpecialistTaxCodesUseCase(this._repository);

  Future<Result<Set<String>>> call() =>
      _repository.getExcludedSpecialistTaxCodes();
}
