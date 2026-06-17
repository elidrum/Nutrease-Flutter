import '../../core/error/result.dart';
import '../model/link_request_with_patient.dart';
import '../repository/link_request_repository.dart';

/// Carica la inbox pendente dello specialista (RF15). Le RLS limitano le righe
/// allo specialista loggato; il repository filtra per stato e ordina per data.
class GetReceivedLinkRequestsUseCase {
  final LinkRequestRepository _repository;

  const GetReceivedLinkRequestsUseCase(this._repository);

  Future<Result<List<LinkRequestWithPatient>>> call() =>
      _repository.getReceivedLinkRequests();
}
