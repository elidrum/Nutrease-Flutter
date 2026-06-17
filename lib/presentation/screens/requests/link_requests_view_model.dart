import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../domain/model/link_request_with_patient.dart';
import '../../../domain/usecase/accept_link_request_use_case.dart';
import '../../../domain/usecase/get_received_link_requests_use_case.dart';
import '../../../domain/usecase/reject_link_request_use_case.dart';

@immutable
class LinkRequestsUiState {
  final Resource<List<LinkRequestWithPatient>> requests;
  final bool isActing;
  final String? error;

  const LinkRequestsUiState({
    this.requests = const Loading(),
    this.isActing = false,
    this.error,
  });

  LinkRequestsUiState copyWith({
    Resource<List<LinkRequestWithPatient>>? requests,
    bool? isActing,
    String? error,
    bool clearError = false,
  }) =>
      LinkRequestsUiState(
        requests: requests ?? this.requests,
        isActing: isActing ?? this.isActing,
        error: clearError ? null : (error ?? this.error),
      );
}

/// ViewModel della inbox dello specialista (RF15–RF17).
///
/// [accept]/[reject] sono single-flight e, al successo, rimuovono la richiesta
/// dalla lista. [pendingCount] alimenta il badge della home.
class LinkRequestsViewModel extends ChangeNotifier {
  final GetReceivedLinkRequestsUseCase _getReceived;
  final AcceptLinkRequestUseCase _accept;
  final RejectLinkRequestUseCase _reject;

  LinkRequestsUiState _state = const LinkRequestsUiState();
  LinkRequestsUiState get state => _state;

  LinkRequestsViewModel({
    required this._getReceived,
    required this._accept,
    required this._reject,
  });


  /// Conteggio richieste pendenti per il badge della home (0 finché non caricato).
  int get pendingCount {
    final requests = _state.requests;
    return requests is Success<List<LinkRequestWithPatient>>
        ? requests.data.length
        : 0;
  }

  Future<void> load() async {
    // Non bloccante sul refresh: tengo la lista visibile durante il reload.
    if (_state.requests is! Success<List<LinkRequestWithPatient>>) {
      _set(_state.copyWith(requests: const Loading()));
    }
    final result = await _getReceived();
    result.fold(
      ok: (items) => _set(_state.copyWith(requests: Success(items))),
      err: (e) => _set(_state.copyWith(requests: Failure(e))),
    );
  }

  Future<bool> accept(int id) => _act(() => _accept(id), id);

  Future<bool> reject(int id, String reason) =>
      _act(() => _reject(id, reason), id);

  Future<bool> _act(Future<Result<void>> Function() action, int id) async {
    if (_state.isActing) return false; // single-flight
    _set(_state.copyWith(isActing: true, clearError: true));
    final result = await action();
    return result.fold(
      ok: (_) {
        _removeFromList(id);
        _set(_state.copyWith(isActing: false));
        return true;
      },
      err: (e) {
        _set(_state.copyWith(isActing: false, error: e.message));
        return false;
      },
    );
  }

  void _removeFromList(int id) {
    final requests = _state.requests;
    if (requests is! Success<List<LinkRequestWithPatient>>) return;
    final remaining =
        requests.data.where((r) => r.request.id != id).toList();
    _state = _state.copyWith(requests: Success(remaining));
  }

  void _set(LinkRequestsUiState next) {
    _state = next;
    notifyListeners();
  }
}
