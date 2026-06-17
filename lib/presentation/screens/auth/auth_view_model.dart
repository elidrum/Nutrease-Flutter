import 'package:flutter/foundation.dart';

import '../../../domain/model/user_role.dart';
import '../../../domain/usecase/login_use_case.dart';
import '../../../domain/usecase/send_password_reset_use_case.dart';

/// Stato UI immutabile della schermata di login.
@immutable
class LoginUiState {
  final bool isLoading;
  final String? error;

  /// Valorizzato al successo; la schermata lo consuma una volta per navigare, poi
  /// il VM lo riazzera a `null` via [AuthViewModel.consumeNavigation].
  final UserRole? navigateTo;
  final bool isSendingReset;
  final bool passwordResetSent;

  const LoginUiState({
    this.isLoading = false,
    this.error,
    this.navigateTo,
    this.isSendingReset = false,
    this.passwordResetSent = false,
  });

  LoginUiState copyWith({
    bool? isLoading,
    String? error,
    UserRole? navigateTo,
    bool? isSendingReset,
    bool? passwordResetSent,
    bool clearError = false,
    bool clearNavigateTo = false,
  }) =>
      LoginUiState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        navigateTo: clearNavigateTo ? null : (navigateTo ?? this.navigateTo),
        isSendingReset: isSendingReset ?? this.isSendingReset,
        passwordResetSent: passwordResetSent ?? this.passwordResetSent,
      );
}

/// ViewModel del login (RF3 + "password dimenticata?"). Single-flight a ogni
/// submit; gli errori restano generici (anti user-enumeration).
class AuthViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;

  AuthViewModel(this._loginUseCase, this._sendPasswordResetUseCase);

  LoginUiState _state = const LoginUiState();
  LoginUiState get state => _state;

  void _set(LoginUiState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (_state.isLoading) return; // single-flight
    _set(_state.copyWith(isLoading: true, clearError: true));
    final result = await _loginUseCase(email.trim(), password);
    result.fold(
      ok: (user) => _set(_state.copyWith(isLoading: false, navigateTo: user.role)),
      err: (e) => _set(_state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    if (_state.isSendingReset) return; // single-flight
    _set(_state.copyWith(isSendingReset: true, clearError: true));
    final result = await _sendPasswordResetUseCase(email);
    result.fold(
      ok: (_) =>
          _set(_state.copyWith(isSendingReset: false, passwordResetSent: true)),
      err: (e) => _set(_state.copyWith(isSendingReset: false, error: e.message)),
    );
  }

  void consumeNavigation() => _set(_state.copyWith(clearNavigateTo: true));
  void consumePasswordResetSent() =>
      _set(_state.copyWith(passwordResetSent: false));
  void clearError() => _set(_state.copyWith(clearError: true));
}
