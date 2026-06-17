import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../model/user_role.dart';
import '../repository/auth_repository.dart';
import '../repository/link_request_repository.dart';

/// Invia una richiesta di collegamento (RF14). Guardia di ruolo: solo un paziente
/// può inviare; le RLS impongono lo stesso
/// server-side.
class SendLinkRequestUseCase {
  final AuthRepository _authRepository;
  final LinkRequestRepository _repository;

  const SendLinkRequestUseCase(this._authRepository, this._repository);

  Future<Result<void>> call(String specialistTaxCode, {String? message}) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null || user.role != UserRole.patient) {
      return const Err(
          ValidationError('Solo un paziente può inviare una richiesta.'));
    }
    return _repository.sendLinkRequest(specialistTaxCode, message: message);
  }
}
