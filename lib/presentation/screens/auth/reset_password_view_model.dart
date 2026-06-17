import 'package:flutter/foundation.dart';

import '../../../core/strings/it_strings.dart';
import '../../../domain/usecase/reset_password_use_case.dart';

@immutable
class ResetPasswordUiState {
  final bool isLoading;
  final String? error;
  final bool done;

  const ResetPasswordUiState({
    this.isLoading = false,
    this.error,
    this.done = false,
  });

  ResetPasswordUiState copyWith({
    bool? isLoading,
    String? error,
    bool? done,
    bool clearError = false,
  }) =>
      ResetPasswordUiState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        done: done ?? this.done,
      );
}

/// ViewModel della schermata di completamento reset password. Submit single-flight.
class ResetPasswordViewModel extends ChangeNotifier {
  final ResetPasswordUseCase _resetPasswordUseCase;

  /// Email a cui è stato inviato il codice OTP (passata dalla rotta).
  final String email;

  ResetPasswordViewModel(this._resetPasswordUseCase, {required this.email});

  ResetPasswordUiState _state = const ResetPasswordUiState();
  ResetPasswordUiState get state => _state;

  void _set(ResetPasswordUiState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> submit({
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_state.isLoading) return; // single-flight
    if (newPassword != confirmPassword) {
      _set(_state.copyWith(error: ItStrings.errorPasswordsMismatch));
      return;
    }
    _set(_state.copyWith(isLoading: true, clearError: true));
    final result = await _resetPasswordUseCase(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    result.fold(
      ok: (_) => _set(_state.copyWith(isLoading: false, done: true)),
      err: (e) => _set(_state.copyWith(isLoading: false, error: e.message)),
    );
  }

  void clearError() => _set(_state.copyWith(clearError: true));
}
