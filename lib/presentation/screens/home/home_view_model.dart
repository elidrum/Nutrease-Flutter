import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../domain/usecase/get_profile_use_case.dart';
import '../../../domain/usecase/logout_use_case.dart';

/// ViewModel minimale della home: carica il nome dell'utente per il saluto e
/// gestisce il logout (RF4). Le voci di funzionalità arrivano negli sprint 3→6.
class HomeViewModel extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final LogoutUseCase _logoutUseCase;

  HomeViewModel(this._getProfileUseCase, this._logoutUseCase);

  Resource<String> _name = const Loading();
  Resource<String> get name => _name;

  bool _navigateToLogin = false;
  bool get navigateToLogin => _navigateToLogin;

  bool _loggingOut = false;

  Future<void> load() async {
    _name = const Loading();
    notifyListeners();
    final result = await _getProfileUseCase();
    result.fold(
      ok: (profile) {
        final firstName =
            profile.patient?.firstName ?? profile.specialist?.firstName ?? '';
        _name = Success(firstName);
        notifyListeners();
      },
      err: (e) {
        _name = Failure(e);
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    if (_loggingOut) return; // single-flight
    _loggingOut = true;
    await _logoutUseCase();
    _navigateToLogin = true;
    notifyListeners();
  }
}
