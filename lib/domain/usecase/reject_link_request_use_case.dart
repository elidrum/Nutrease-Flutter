import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/user_role.dart';
import '../repository/auth_repository.dart';
import '../repository/link_request_repository.dart';

/// Rifiuta una richiesta di collegamento con motivazione obbligatoria (RF17).
/// Guardia di ruolo: solo uno specialista può rifiutare; la motivazione non
/// può essere vuota.
class RejectLinkRequestUseCase {
  final AuthRepository _authRepository;
  final LinkRequestRepository _repository;

  const RejectLinkRequestUseCase(this._authRepository, this._repository);

  Future<Result<void>> call(int requestId, String reason) async {
    if (reason.trim().isEmpty) {
      return const Err(ValidationError('La motivazione è obbligatoria.'));
    }
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.role != UserRole.specialist) {
      return const Err(
          ValidationError('Solo uno specialista può rifiutare una richiesta.'));
    }
    return _repository.rejectLinkRequest(requestId, reason.trim());
  }
}
