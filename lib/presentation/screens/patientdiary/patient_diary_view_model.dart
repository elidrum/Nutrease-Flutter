import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../domain/model/diary_date_range.dart';
import '../../../domain/model/nutrient_filter.dart';
import '../../../domain/model/patient_diary_day.dart';
import '../../../domain/usecase/get_patient_diary_range_use_case.dart';

@immutable
class PatientDiaryUiState {
  final String patientName;
  final DiaryDateRange range;
  final NutrientFilter filter;
  final Resource<List<PatientDiaryDay>> days;

  /// Ultimo messaggio d'errore mostrato (es. il cap di 92 giorni), rispecchiato da
  /// una fetch fallita così la UI può mostrarlo senza ri-derivarlo.
  final String? error;

  const PatientDiaryUiState({
    required this.patientName,
    required this.range,
    this.filter = NutrientFilter.all,
    this.days = const Loading(),
    this.error,
  });

  PatientDiaryUiState copyWith({
    DiaryDateRange? range,
    NutrientFilter? filter,
    Resource<List<PatientDiaryDay>>? days,
    String? error,
    bool clearError = false,
  }) =>
      PatientDiaryUiState(
        patientName: patientName,
        range: range ?? this.range,
        filter: filter ?? this.filter,
        days: days ?? this.days,
        error: clearError ? null : (error ?? this.error),
      );
}

/// ViewModel del diario paziente in sola lettura (RF19/RF20).
///
/// **Non** espone operazioni di create/update/delete: la vista è read-only
/// (ADR-0016; le RLS bloccherebbero comunque le scritture). [setRange] annulla la
/// fetch precedente in corso via un token incrementale e ri-legge, mappando il
/// [ValidationError] dei 92 giorni del use case (ADR-0017) in
/// [PatientDiaryUiState.error]. [setNutrientFilter] è un aggiornamento di stato
/// puro — l'evidenziazione è lato client, quindi non rilegge mai.
class PatientDiaryViewModel extends ChangeNotifier {
  final int _fascicoloId;
  final GetPatientDiaryRangeUseCase _getRange;

  int _fetchToken = 0;

  PatientDiaryUiState _state;
  PatientDiaryUiState get state => _state;

  PatientDiaryViewModel({
    required this._fascicoloId,
    required String patientName,
    required this._getRange,
  }) : _state = PatientDiaryUiState(
          patientName: patientName,
          range: DiaryDateRange.today(),
        );

  Future<void> load() => _fetch(_state.range);

  /// Riprova l'intervallo attualmente selezionato (usato dalla error view).
  Future<void> retry() => _fetch(_state.range);

  /// Cambia il periodo e ri-legge, annullando ogni fetch in corso.
  void setRange(DiaryDateRange range) {
    _set(_state.copyWith(range: range, clearError: true));
    _fetch(range);
  }

  /// Seleziona il nutriente evidenziato. Solo stato: niente re-fetch (RF20).
  void setNutrientFilter(NutrientFilter filter) {
    _set(_state.copyWith(filter: filter));
  }

  Future<void> _fetch(DiaryDateRange range) async {
    final token = ++_fetchToken;
    _set(_state.copyWith(days: const Loading(), clearError: true));

    final result = await _getRange(_fascicoloId, range);
    if (token != _fetchToken) return; // soppiantato da un intervallo più recente

    result.fold(
      ok: (days) => _set(_state.copyWith(days: Success(days))),
      err: (error) =>
          _set(_state.copyWith(days: Failure(error), error: error.message)),
    );
  }

  void _set(PatientDiaryUiState next) {
    _state = next;
    notifyListeners();
  }
}
