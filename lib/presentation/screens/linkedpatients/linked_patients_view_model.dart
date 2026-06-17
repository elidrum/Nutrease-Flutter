import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../domain/model/linked_patient.dart';
import '../../../domain/usecase/get_linked_patients_use_case.dart';

@immutable
class LinkedPatientsUiState {
  final Resource<List<LinkedPatient>> patients;

  const LinkedPatientsUiState({this.patients = const Loading()});

  LinkedPatientsUiState copyWith({
    Resource<List<LinkedPatient>>? patients,
  }) =>
      LinkedPatientsUiState(patients: patients ?? this.patients);
}

/// ViewModel della lista pazienti collegati (RF18).
///
/// [load] fa anche da pull-to-refresh: tiene visibile la lista corrente durante
/// il reload così un refresh non fa lampeggiare uno spinner sui dati esistenti.
class LinkedPatientsViewModel extends ChangeNotifier {
  final GetLinkedPatientsUseCase _getLinkedPatients;

  LinkedPatientsUiState _state = const LinkedPatientsUiState();
  LinkedPatientsUiState get state => _state;

  LinkedPatientsViewModel({required this._getLinkedPatients});

  Future<void> load() async {
    // Non bloccante sul refresh: il loader a tutto schermo solo al primo caricamento.
    if (_state.patients is! Success<List<LinkedPatient>>) {
      _set(_state.copyWith(patients: const Loading()));
    }
    final result = await _getLinkedPatients();
    result.fold(
      ok: (patients) => _set(_state.copyWith(patients: Success(patients))),
      err: (error) => _set(_state.copyWith(patients: Failure(error))),
    );
  }

  void _set(LinkedPatientsUiState next) {
    _state = next;
    notifyListeners();
  }
}
