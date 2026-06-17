import 'package:flutter/foundation.dart';

import '../../../domain/model/specialist.dart';
import '../../../domain/usecase/get_linked_specialist_use_case.dart';

@immutable
class PatientHomeUiState {
  final Specialist? linkedSpecialist;

  /// Distingue "non ancora caricato" (non mostrare nulla, niente flicker) da
  /// "caricato, nessuno collegato" (mostra lo stato vuoto).
  final bool isLinkedSpecialistLoaded;

  const PatientHomeUiState({
    this.linkedSpecialist,
    this.isLinkedSpecialistLoaded = false,
  });
}

/// ViewModel minimale della home paziente: porta solo lo specialista collegato per
/// la card "Il tuo specialista" (delta Android 2026-06-12). Esclude di proposito i
/// contatori badge di Android (chat tagliata; richieste accettate fuori scope).
class PatientHomeViewModel extends ChangeNotifier {
  final GetLinkedSpecialistUseCase _getLinkedSpecialist;

  PatientHomeUiState _state = const PatientHomeUiState();
  PatientHomeUiState get state => _state;

  PatientHomeViewModel(this._getLinkedSpecialist);

  /// Ricarica lo specialista collegato. Invocato all'init e al ritorno in home
  /// (ADR-0014). Un errore transitorio lascia lo stato "non caricato" così lo
  /// stato vuoto non viene mostrato per sbaglio; un refresh successivo recupera.
  Future<void> refresh() async {
    final result = await _getLinkedSpecialist();
    result.fold(
      ok: (specialist) {
        _state = PatientHomeUiState(
          linkedSpecialist: specialist,
          isLinkedSpecialistLoaded: true,
        );
        notifyListeners();
      },
      err: (_) {/* resta non-caricato: evita un falso stato "nessuno specialista" */},
    );
  }
}
