import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../domain/model/symptom.dart';
import '../../../domain/model/symptom_severity.dart';
import '../../../domain/model/symptom_type.dart';
import '../../../domain/usecase/add_symptom_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../../domain/usecase/get_symptom_use_case.dart';
import '../../../domain/usecase/update_symptom_use_case.dart';

@immutable
class AddSymptomUiState {
  final SymptomType type;
  final SymptomSeverity severity;
  final DateTime date;

  /// `HH:mm:ss` (formato della colonna `time` del DB).
  final String time;

  /// Etichetta testuale digitata quando [type] è [SymptomType.other].
  final String otherDescription;
  final bool isSaving;
  final String? error;
  final bool saved;
  final bool isEditing;

  /// True mentre il sintomo esistente viene caricato per il prefill di modifica.
  final bool isLoadingExisting;

  const AddSymptomUiState({
    this.type = SymptomType.bloating,
    this.severity = SymptomSeverity.mild,
    required this.date,
    required this.time,
    this.otherDescription = '',
    this.isSaving = false,
    this.error,
    this.saved = false,
    this.isEditing = false,
    this.isLoadingExisting = false,
  });

  AddSymptomUiState copyWith({
    SymptomType? type,
    SymptomSeverity? severity,
    DateTime? date,
    String? time,
    String? otherDescription,
    bool? isSaving,
    String? error,
    bool? saved,
    bool? isEditing,
    bool? isLoadingExisting,
    bool clearError = false,
  }) =>
      AddSymptomUiState(
        type: type ?? this.type,
        severity: severity ?? this.severity,
        date: date ?? this.date,
        time: time ?? this.time,
        otherDescription: otherDescription ?? this.otherDescription,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
        saved: saved ?? this.saved,
        isEditing: isEditing ?? this.isEditing,
        isLoadingExisting: isLoadingExisting ?? this.isLoadingExisting,
      );
}

/// ViewModel di aggiunta/modifica sintomo (RF10).
///
/// Il parametro `symptom_id` della rotta decide la modalità (ADR-0013): `null`/`0`
/// è inserimento, `> 0` è modifica ([init] pre-compila via `GetSymptomUseCase`).
/// [submit] è single-flight.
class AddSymptomViewModel extends ChangeNotifier {
  final AddSymptomUseCase _addSymptomUseCase;
  final UpdateSymptomUseCase _updateSymptomUseCase;
  final GetSymptomUseCase _getSymptomUseCase;
  final GetPatientFascicoloUseCase _getPatientFascicoloUseCase;

  final int? _editingSymptomId;

  /// Fascicolo del sintomo in modifica; evita di ri-risolverlo al submit.
  int? _fascicoloIdForEdit;

  AddSymptomUiState _state;
  AddSymptomUiState get state => _state;

  AddSymptomViewModel({
    required this._addSymptomUseCase,
    required this._updateSymptomUseCase,
    required this._getSymptomUseCase,
    required this._getPatientFascicoloUseCase,
    int? symptomId,
    DateTime? initialDate,
  })  : _editingSymptomId =
            (symptomId != null && symptomId > 0) ? symptomId : null,
        _state = AddSymptomUiState(
          date: initialDate ?? DateTime.now(),
          time: formatTime(DateTime.now()),
          isEditing: symptomId != null && symptomId > 0,
          isLoadingExisting: symptomId != null && symptomId > 0,
        );

  /// In modalità modifica, carica e pre-compila il sintomo esistente.
  Future<void> init() async {
    final symptomId = _editingSymptomId;
    if (symptomId == null) return;
    final result = await _getSymptomUseCase(symptomId);
    result.fold(
      ok: (symptom) {
        _fascicoloIdForEdit = symptom.fascicoloId;
        _set(_state.copyWith(
          isLoadingExisting: false,
          date: symptom.date,
          time: symptom.time,
          type: symptom.type,
          // "Assente" non è più selezionabile; mappo l'eventuale none legacy → mild.
          severity: symptom.severity == SymptomSeverity.none
              ? SymptomSeverity.mild
              : symptom.severity,
          otherDescription: symptom.otherDescription ?? '',
        ));
      },
      err: (e) =>
          _set(_state.copyWith(isLoadingExisting: false, error: e.message)),
    );
  }

  void setType(SymptomType type) => _set(_state.copyWith(type: type));

  void setOtherDescription(String value) =>
      _set(_state.copyWith(otherDescription: value));

  void setSeverity(SymptomSeverity severity) =>
      _set(_state.copyWith(severity: severity));

  void setDate(DateTime date) => _set(_state.copyWith(date: date));

  void setTime(String time) => _set(_state.copyWith(time: time));

  /// Salvataggio single-flight: sceglie insert o update dal parametro di rotta
  /// (ADR-0013) e risolve il fascicolo in inserimento.
  Future<void> submit() async {
    if (_state.isSaving) return;

    // Guardie lato client (RF10): niente date future, e "Altro" richiede un'etichetta.
    final now = DateTime.now();
    final selectedDay = DateTime(_state.date.year, _state.date.month, _state.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAfter(today)) {
      _set(_state.copyWith(error: ItStrings.errorFutureSymptomDate));
      return;
    }
    if (_state.type == SymptomType.other &&
        _state.otherDescription.trim().isEmpty) {
      _set(_state.copyWith(error: ItStrings.errorSymptomOtherRequired));
      return;
    }

    _set(_state.copyWith(isSaving: true, clearError: true));

    final int fascicoloId;
    final fascicoloForEdit = _fascicoloIdForEdit;
    if (fascicoloForEdit != null) {
      fascicoloId = fascicoloForEdit;
    } else {
      final fascicoloResult = await _getPatientFascicoloUseCase();
      switch (fascicoloResult) {
        case Ok(:final value):
          fascicoloId = value;
        case Err(:final error):
          _set(_state.copyWith(isSaving: false, error: error.message));
          return;
      }
    }

    final symptom = Symptom(
      id: _editingSymptomId,
      fascicoloId: fascicoloId,
      date: _state.date,
      time: _state.time,
      type: _state.type,
      severity: _state.severity,
      otherDescription: _state.type == SymptomType.other
          ? _state.otherDescription.trim()
          : null,
    );

    final result = _editingSymptomId != null
        ? await _updateSymptomUseCase(symptom)
        : await _addSymptomUseCase(symptom);
    result.fold(
      ok: (_) => _set(_state.copyWith(isSaving: false, saved: true)),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  void clearError() => _set(_state.copyWith(clearError: true));

  void _set(AddSymptomUiState next) {
    _state = next;
    notifyListeners();
  }

  /// Formatta l'orario di un [DateTime] come `HH:mm:ss`.
  static String formatTime(DateTime dateTime) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dateTime.hour)}:${pad(dateTime.minute)}:00';
  }
}
