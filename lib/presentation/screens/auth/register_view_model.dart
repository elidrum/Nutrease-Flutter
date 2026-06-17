import 'package:flutter/foundation.dart';

import '../../../core/strings/it_strings.dart';
import '../../../domain/model/age_policy.dart';
import '../../../domain/model/gender.dart';
import '../../../domain/model/password_policy.dart';
import '../../../domain/model/register_data.dart';
import '../../../domain/model/specialization_type.dart';
import '../../../domain/model/user_role.dart';
import '../../../domain/usecase/register_use_case.dart';

/// Quale form di registrazione è attivo.
enum RegisterTab { patient, specialist }

/// Chiavi dei campi usate in [RegisterUiState.fieldErrors] per i messaggi inline.
abstract final class RegisterField {
  static const String firstName = 'firstName';
  static const String surname = 'surname';
  static const String taxCode = 'taxCode';
  static const String email = 'email';
  static const String password = 'password';
  static const String birthDate = 'birthDate';
  static const String gender = 'gender';
  static const String vatNumber = 'vatNumber';
  static const String specialization = 'specialization';
  static const String city = 'city';
}

@immutable
class RegisterUiState {
  final RegisterTab tab;
  final bool isLoading;
  final String? error;
  final Map<String, String> fieldErrors;

  /// Valorizzato al successo; consumato una volta dalla schermata per navigare
  /// alla home del ruolo.
  final UserRole? navigateTo;

  const RegisterUiState({
    this.tab = RegisterTab.patient,
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.navigateTo,
  });

  RegisterUiState copyWith({
    RegisterTab? tab,
    bool? isLoading,
    String? error,
    Map<String, String>? fieldErrors,
    UserRole? navigateTo,
    bool clearError = false,
    bool clearNavigateTo = false,
  }) =>
      RegisterUiState(
        tab: tab ?? this.tab,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        fieldErrors: fieldErrors ?? this.fieldErrors,
        navigateTo: clearNavigateTo ? null : (navigateTo ?? this.navigateTo),
      );
}

/// ViewModel della registrazione (RF1/RF2). Valida i campi con [PasswordPolicy] /
/// [AgePolicy] e vincoli inline, poi invia in single-flight.
class RegisterViewModel extends ChangeNotifier {
  final RegisterUseCase _registerUseCase;

  RegisterViewModel(this._registerUseCase);

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  RegisterUiState _state = const RegisterUiState();
  RegisterUiState get state => _state;

  void _set(RegisterUiState next) {
    _state = next;
    notifyListeners();
  }

  void selectTab(RegisterTab tab) {
    if (_state.isLoading || tab == _state.tab) return;
    _set(_state.copyWith(tab: tab, fieldErrors: const {}, clearError: true));
  }

  Future<void> submitPatient({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String taxCode,
    required Gender? gender,
    required String birthDateText,
  }) async {
    if (_state.isLoading) return; // single-flight

    final errors = _validateCommon(
      email: email,
      password: password,
      firstName: firstName,
      surname: surname,
      taxCode: taxCode,
    );
    final birthDate = _parseDate(birthDateText);
    if (birthDate == null || !AgePolicy.isValidBirthDate(birthDate)) {
      errors[RegisterField.birthDate] = ItStrings.errorBirthDateInvalid;
    }
    if (gender == null) {
      errors[RegisterField.gender] = ItStrings.errorGenderRequired;
    }
    if (errors.isNotEmpty) {
      _set(_state.copyWith(fieldErrors: errors));
      return;
    }

    await _submit(
      PatientRegisterData(
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        surname: surname.trim(),
        taxCode: taxCode.trim().toUpperCase(),
        gender: gender!,
        birthDate: birthDate!,
      ),
      UserRole.patient,
    );
  }

  Future<void> submitSpecialist({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String taxCode,
    required String vatNumber,
    required SpecializationType? specialization,
    required String city,
  }) async {
    if (_state.isLoading) return; // single-flight

    final errors = _validateCommon(
      email: email,
      password: password,
      firstName: firstName,
      surname: surname,
      taxCode: taxCode,
    );
    if (vatNumber.trim().length != 11 ||
        int.tryParse(vatNumber.trim()) == null) {
      errors[RegisterField.vatNumber] = ItStrings.errorVatNumberLength;
    }
    if (specialization == null) {
      errors[RegisterField.specialization] =
          ItStrings.errorSpecializationRequired;
    }
    if (city.trim().isEmpty) {
      errors[RegisterField.city] = ItStrings.errorCityRequired;
    }
    if (errors.isNotEmpty) {
      _set(_state.copyWith(fieldErrors: errors));
      return;
    }

    await _submit(
      SpecialistRegisterData(
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        surname: surname.trim(),
        taxCode: taxCode.trim().toUpperCase(),
        vatNumber: vatNumber.trim(),
        specialization: specialization!,
        city: city.trim(),
      ),
      UserRole.specialist,
    );
  }

  Future<void> _submit(RegisterData data, UserRole role) async {
    _set(_state.copyWith(
        isLoading: true, fieldErrors: const {}, clearError: true));
    final result = await _registerUseCase(data);
    result.fold(
      ok: (_) => _set(_state.copyWith(isLoading: false, navigateTo: role)),
      err: (e) => _set(_state.copyWith(isLoading: false, error: e.message)),
    );
  }

  Map<String, String> _validateCommon({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String taxCode,
  }) {
    final errors = <String, String>{};
    if (firstName.trim().isEmpty) {
      errors[RegisterField.firstName] = ItStrings.errorFirstNameRequired;
    }
    if (surname.trim().isEmpty) {
      errors[RegisterField.surname] = ItStrings.errorSurnameRequired;
    }
    if (taxCode.trim().length != 16) {
      errors[RegisterField.taxCode] = ItStrings.errorTaxCodeLength;
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      errors[RegisterField.email] = ItStrings.errorEmailInvalid;
    }
    final passwordError = PasswordPolicy.validate(password);
    if (passwordError != null) {
      errors[RegisterField.password] = passwordError;
    }
    return errors;
  }

  /// Parsa una stringa `gg/mm/aaaa` in una data di calendario reale, o `null`.
  static DateTime? _parseDate(String text) {
    final parts = text.split('/');
    if (parts.length != 3 || parts[2].length != 4) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    // Scarto le date in overflow (es. 31/02 che scivola a marzo).
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  void consumeNavigation() => _set(_state.copyWith(clearNavigateTo: true));
  void clearError() => _set(_state.copyWith(clearError: true));
}
