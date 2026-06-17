import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../domain/model/patient.dart';
import '../../../domain/model/specialist.dart';
import '../../../domain/model/user_profile.dart';
import '../../../domain/usecase/change_password_use_case.dart';
import '../../../domain/usecase/delete_account_use_case.dart';
import '../../../domain/usecase/get_profile_use_case.dart';
import '../../../domain/usecase/logout_use_case.dart';
import '../../../domain/usecase/update_patient_use_case.dart';
import '../../../domain/usecase/update_specialist_use_case.dart';

@immutable
class ProfileUiState {
  final Resource<UserProfile> profile;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final bool navigateToLogin;

  const ProfileUiState({
    this.profile = const Loading(),
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.navigateToLogin = false,
  });

  ProfileUiState copyWith({
    Resource<UserProfile>? profile,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool? navigateToLogin,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      ProfileUiState(
        profile: profile ?? this.profile,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
        navigateToLogin: navigateToLogin ?? this.navigateToLogin,
      );
}

/// ViewModel del profilo (RF4–RF7). Carica il profilo in [load]; ogni azione di
/// modifica è single-flight.
class ProfileViewModel extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final UpdatePatientUseCase _updatePatientUseCase;
  final UpdateSpecialistUseCase _updateSpecialistUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final LogoutUseCase _logoutUseCase;

  ProfileViewModel(
    this._getProfileUseCase,
    this._updatePatientUseCase,
    this._updateSpecialistUseCase,
    this._changePasswordUseCase,
    this._deleteAccountUseCase,
    this._logoutUseCase,
  );

  ProfileUiState _state = const ProfileUiState();
  ProfileUiState get state => _state;

  void _set(ProfileUiState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _set(_state.copyWith(profile: const Loading()));
    final result = await _getProfileUseCase();
    result.fold(
      ok: (profile) => _set(_state.copyWith(profile: Success(profile))),
      err: (e) => _set(_state.copyWith(profile: Failure(e))),
    );
  }

  Future<void> savePatient(Patient patient) async {
    if (_state.isSaving) return;
    _set(_state.copyWith(isSaving: true, clearError: true));
    final result = await _updatePatientUseCase(patient);
    result.fold(
      ok: (_) => _set(_state.copyWith(
        isSaving: false,
        profile: _withPatient(patient),
        successMessage: ItStrings.profileUpdated,
      )),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  Future<void> saveSpecialist(Specialist specialist) async {
    if (_state.isSaving) return;
    _set(_state.copyWith(isSaving: true, clearError: true));
    final result = await _updateSpecialistUseCase(specialist);
    result.fold(
      ok: (_) => _set(_state.copyWith(
        isSaving: false,
        profile: _withSpecialist(specialist),
        successMessage: ItStrings.profileUpdated,
      )),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_state.isSaving) return;
    _set(_state.copyWith(isSaving: true, clearError: true));
    final result = await _changePasswordUseCase(currentPassword, newPassword);
    result.fold(
      ok: (_) => _set(_state.copyWith(
          isSaving: false, successMessage: ItStrings.passwordUpdated)),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  Future<void> deleteAccount(String password) async {
    if (_state.isSaving) return;
    _set(_state.copyWith(isSaving: true, clearError: true));
    final result = await _deleteAccountUseCase(password);
    result.fold(
      ok: (_) => _set(_state.copyWith(isSaving: false, navigateToLogin: true)),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  Future<void> logout() async {
    if (_state.isSaving) return;
    _set(_state.copyWith(isSaving: true));
    await _logoutUseCase();
    _set(_state.copyWith(isSaving: false, navigateToLogin: true));
  }

  /// Ricostruisce il profilo caricato con un paziente aggiornato (lo tiene a
  /// schermo senza re-fetch).
  Resource<UserProfile> _withPatient(Patient patient) {
    final current = _state.profile;
    if (current is! Success<UserProfile>) return current;
    final p = current.data;
    return Success(UserProfile(
      userId: p.userId,
      role: p.role,
      taxCode: p.taxCode,
      patient: patient,
    ));
  }

  Resource<UserProfile> _withSpecialist(Specialist specialist) {
    final current = _state.profile;
    if (current is! Success<UserProfile>) return current;
    final p = current.data;
    return Success(UserProfile(
      userId: p.userId,
      role: p.role,
      taxCode: p.taxCode,
      specialist: specialist,
    ));
  }

  void clearError() => _set(_state.copyWith(clearError: true));
  void clearSuccess() => _set(_state.copyWith(clearSuccess: true));
}
