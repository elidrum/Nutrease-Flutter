import 'package:flutter/foundation.dart';

import '../../../domain/model/user_role.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../navigation/routes.dart';

/// Stato UI immutabile della splash.
@immutable
class RootUiState {
  final bool loading;
  final String? targetRoute;

  const RootUiState({this.loading = true, this.targetRoute});

  RootUiState copyWith({bool? loading, String? targetRoute}) => RootUiState(
        loading: loading ?? this.loading,
        targetRoute: targetRoute ?? this.targetRoute,
      );
}

/// Decide la destinazione iniziale all'avvio (auto-login RF3, ADR-0021).
///
/// `getCurrentUser()` legge la sessione ripristinata e risolve il ruolo:
/// paziente → home paziente, specialista → home specialista, nessuno → login.
class RootViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  RootViewModel(this._authRepository);

  RootUiState _state = const RootUiState();
  RootUiState get state => _state;

  Future<void> resolveStartDestination() async {
    final user = await _authRepository.getCurrentUser();
    final target = switch (user?.role) {
      UserRole.patient => Routes.patientHome,
      UserRole.specialist => Routes.specialistHome,
      null => Routes.login,
    };
    _state = _state.copyWith(loading: false, targetRoute: target);
    notifyListeners();
  }
}
