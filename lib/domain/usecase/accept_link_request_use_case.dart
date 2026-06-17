import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/user_role.dart';
import '../repository/auth_repository.dart';
import '../repository/link_request_repository.dart';

/// Accetta una richiesta di collegamento (RF16). Guardia di ruolo: solo uno
/// specialista può accettare; le RLS impongono lo
/// stesso
/// server-side.
class AcceptLinkRequestUseCase {
  final AuthRepository _authRepository;
  final LinkRequestRepository _repository;

  const AcceptLinkRequestUseCase(this._authRepository, this._repository);

  Future<Result<void>> call(int requestId) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.role != UserRole.specialist) {
      return const Err(
          ValidationError('Solo uno specialista può accettare una richiesta.'));
    }
    return _repository.acceptLinkRequest(requestId);
  }
}
