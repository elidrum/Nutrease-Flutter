import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../domain/model/daily_diary.dart';
import '../../../domain/model/meal.dart';
import '../../../domain/model/symptom.dart';
import '../../../domain/usecase/delete_meal_use_case.dart';
import '../../../domain/usecase/delete_symptom_use_case.dart';
import '../../../domain/usecase/get_daily_diary_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';

@immutable
class DiaryUiState {
  final DateTime selectedDate;
  final Resource<DailyDiary> diary;

  const DiaryUiState({
    required this.selectedDate,
    this.diary = const Loading(),
  });

  DiaryUiState copyWith({
    DateTime? selectedDate,
    Resource<DailyDiary>? diary,
  }) =>
      DiaryUiState(
        selectedDate: selectedDate ?? this.selectedDate,
        diary: diary ?? this.diary,
      );
}

/// ViewModel della timeline del diario (RF11/RF12).
///
/// Risolve una volta il `fascicoloId` attivo via `GetPatientFascicoloUseCase`
/// (ri-risolto se era fallito), poi carica il [DailyDiary] fuso per la data
/// selezionata. [refresh] è idempotente e last-write-wins (le risposte stale da
/// cambi data rapidi vengono scartate), quindi è sicuro chiamarlo a ogni rientro
/// nella schermata (ADR-0014).
class DiaryViewModel extends ChangeNotifier {
  final GetDailyDiaryUseCase _getDailyDiaryUseCase;
  final GetPatientFascicoloUseCase _getPatientFascicoloUseCase;
  final DeleteMealUseCase _deleteMealUseCase;
  final DeleteSymptomUseCase _deleteSymptomUseCase;

  int? _fascicoloId;

  /// Token incrementale per scartare le risposte async stale (last write wins).
  int _requestId = 0;

  DiaryUiState _state;
  DiaryUiState get state => _state;

  DiaryViewModel({
    required this._getDailyDiaryUseCase,
    required this._getPatientFascicoloUseCase,
    required this._deleteMealUseCase,
    required this._deleteSymptomUseCase,
    DateTime? initialDate,
  }) : _state = DiaryUiState(
          selectedDate: _dateOnly(initialDate ?? DateTime.now()),
        );

  void selectDate(DateTime date) {
    _set(_state.copyWith(selectedDate: _dateOnly(date)));
    refresh();
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    // Refresh non bloccante (ADR-0014): continuo a mostrare i dati correnti
    // durante il reload; solo il primo caricamento (o un retry dopo errore)
    // mostra lo spinner.
    if (_state.diary is! Success<DailyDiary>) {
      _set(_state.copyWith(diary: const Loading()));
    }

    final fascicoloId = await _resolveFascicoloId();
    if (requestId != _requestId) return;
    if (fascicoloId == null) return; // _resolveFascicoloId ha già impostato l'errore

    final result =
        await _getDailyDiaryUseCase(fascicoloId, _state.selectedDate);
    if (requestId != _requestId) return;
    result.fold(
      ok: (diary) => _set(_state.copyWith(diary: Success(diary))),
      err: (e) => _set(_state.copyWith(diary: Failure(e))),
    );
  }

  /// Elimina un pasto: lo rimuove in modo ottimistico (così l'elemento dismesso
  /// esce pulito dall'albero), poi cancella e ri-legge per riconciliare.
  /// Restituisce se la cancellazione è andata a buon fine.
  Future<bool> deleteMeal(int mealId) async {
    _removeOptimistically(mealId: mealId);
    final result = await _deleteMealUseCase(mealId);
    await refresh();
    return result is Ok<void>;
  }

  /// Elimina un sintomo (rimozione ottimistica + riconciliazione); restituisce l'esito.
  Future<bool> deleteSymptom(int symptomId) async {
    _removeOptimistically(symptomId: symptomId);
    final result = await _deleteSymptomUseCase(symptomId);
    await refresh();
    return result is Ok<void>;
  }

  void _removeOptimistically({int? mealId, int? symptomId}) {
    final diary = _state.diary;
    if (diary is! Success<DailyDiary>) return;
    final current = diary.data;
    _set(_state.copyWith(
      diary: Success(DailyDiary(
        date: current.date,
        meals: mealId == null
            ? current.meals
            : current.meals.where((Meal m) => m.id != mealId).toList(),
        symptoms: symptomId == null
            ? current.symptoms
            : current.symptoms
                .where((Symptom s) => s.id != symptomId)
                .toList(),
      )),
    ));
  }

  /// Restituisce il fascicolo id in cache, risolvendolo al primo uso. In caso di
  /// errore imposta lo stato d'errore del diario e restituisce `null`.
  Future<int?> _resolveFascicoloId() async {
    final cached = _fascicoloId;
    if (cached != null) return cached;
    final result = await _getPatientFascicoloUseCase();
    switch (result) {
      case Ok(:final value):
        _fascicoloId = value;
        return value;
      case Err(:final error):
        _set(_state.copyWith(diary: Failure(error)));
        return null;
    }
  }

  void _set(DiaryUiState next) {
    _state = next;
    notifyListeners();
  }

  /// Toglie la componente oraria così confronti/chiavi per data restano stabili.
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
