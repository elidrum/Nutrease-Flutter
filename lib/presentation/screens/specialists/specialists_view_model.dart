import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/model/specialist.dart';
import '../../../domain/model/specialization_type.dart';
import '../../../domain/usecase/get_excluded_specialist_tax_codes_use_case.dart';
import '../../../domain/usecase/get_linked_specialist_use_case.dart';
import '../../../domain/usecase/search_specialists_use_case.dart';
import '../../../domain/usecase/send_link_request_use_case.dart';

@immutable
class SpecialistsUiState {
  final String text;
  final SpecializationType? specialization;
  final String city;
  final List<Specialist> items;
  final bool isLoadingPage;
  final bool hasMore;

  /// True una volta che la prima pagina si è risolta (ok o errore). Distingue la
  /// finestra pre-init (mostra un loader) da un risultato davvero vuoto.
  final bool firstPageDone;

  /// Prossimo indice di pagina (0-based) da caricare.
  final int page;
  final String? error;

  /// Specialisti nascosti dalla discovery (già collegati o pendenti).
  final Set<String> excluded;

  /// "Nome Cognome" dello specialista attualmente collegato, o `null` quando non
  /// c'è / non ancora noto — guida l'avviso di sostituzione.
  final String? linkedSpecialistName;

  const SpecialistsUiState({
    this.text = '',
    this.specialization,
    this.city = '',
    this.items = const [],
    this.isLoadingPage = false,
    this.hasMore = true,
    this.firstPageDone = false,
    this.page = 0,
    this.error,
    this.excluded = const {},
    this.linkedSpecialistName,
  });

  SpecialistsUiState copyWith({
    String? text,
    SpecializationType? specialization,
    bool clearSpecialization = false,
    String? city,
    List<Specialist>? items,
    bool? isLoadingPage,
    bool? hasMore,
    bool? firstPageDone,
    int? page,
    String? error,
    bool clearError = false,
    Set<String>? excluded,
    String? linkedSpecialistName,
    bool clearLinkedName = false,
  }) =>
      SpecialistsUiState(
        text: text ?? this.text,
        specialization:
            clearSpecialization ? null : (specialization ?? this.specialization),
        city: city ?? this.city,
        items: items ?? this.items,
        isLoadingPage: isLoadingPage ?? this.isLoadingPage,
        hasMore: hasMore ?? this.hasMore,
        firstPageDone: firstPageDone ?? this.firstPageDone,
        page: page ?? this.page,
        error: clearError ? null : (error ?? this.error),
        excluded: excluded ?? this.excluded,
        linkedSpecialistName: clearLinkedName
            ? null
            : (linkedSpecialistName ?? this.linkedSpecialistName),
      );

  /// Mostra il loader a tutto schermo: la prima pagina sta caricando, o l'init non
  /// ha ancora prodotto un primo risultato (copre la finestra pre-ricerca, niente flash).
  bool get isInitialLoading =>
      (isLoadingPage && items.isEmpty) || (!firstPageDone && error == null);

  /// Nessun risultato e non in caricamento/errore (stato vuoto).
  bool get isEmpty =>
      firstPageDone && !isLoadingPage && items.isEmpty && error == null;
}

/// ViewModel della discovery (RF13/RF14).
///
/// I filtri testo/città sono in debounce (300 ms); il dropdown specializzazione
/// si applica subito. La paginazione sovra-carica `pageSize + |excluded|` righe
/// così il filtro di esclusione lato client non lascia buchi, e l'infinite-scroll
/// carica la pagina successiva verso la fine. Un token incrementale scarta i risultati
/// di una ricerca soppiantata da un cambio filtro. [sendRequest] è single-flight.
class SpecialistsViewModel extends ChangeNotifier {
  final SearchSpecialistsUseCase _searchSpecialists;
  final SendLinkRequestUseCase _sendLinkRequest;
  final GetExcludedSpecialistTaxCodesUseCase _getExcluded;
  final GetLinkedSpecialistUseCase _getLinkedSpecialist;

  final int pageSize;

  /// Iniettabile così i test possono accorciare la finestra di debounce.
  final Duration debounceDuration;

  Timer? _debounce;
  int _searchToken = 0;
  bool _sending = false;
  bool _linkedFetchOk = false;
  String? _lastQueryKey;

  SpecialistsUiState _state = const SpecialistsUiState();
  SpecialistsUiState get state => _state;

  SpecialistsViewModel({
    required this._searchSpecialists,
    required this._sendLinkRequest,
    required this._getExcluded,
    required this._getLinkedSpecialist,
    this.pageSize = 20,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  /// Carica le esclusioni + lo specialista collegato, poi la prima pagina.
  Future<void> init() async {
    final excludedResult = await _getExcluded();
    excludedResult.fold(
      ok: (set) => _state = _state.copyWith(excluded: set),
      err: (_) {/* best-effort: la discovery funziona comunque, solo non filtrata */},
    );
    await _loadLinkedSpecialist();
    await _resetAndSearch();
  }

  void setText(String text) {
    _state = _state.copyWith(text: text);
    notifyListeners();
    _scheduleSearch();
  }

  void setCity(String city) {
    _state = _state.copyWith(city: city);
    notifyListeners();
    _scheduleSearch();
  }

  void setSpecialization(SpecializationType? specialization) {
    // I cambi del dropdown si applicano subito (niente debounce).
    _debounce?.cancel();
    _state = specialization == null
        ? _state.copyWith(clearSpecialization: true)
        : _state.copyWith(specialization: specialization);
    notifyListeners();
    _resetAndSearch();
  }

  /// Riprova la ricerca corrente dopo un errore sulla prima pagina.
  Future<void> retry() => _resetAndSearch();

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, _resetAndSearch);
  }

  String get _queryKey =>
      '${_state.text.trim()}|${_state.specialization?.dbLabel ?? ''}|'
      '${_state.city.trim()}';

  Future<void> _resetAndSearch() async {
    final key = _queryKey;
    // distinctUntilChanged: salto una query identica e già soddisfatta.
    if (key == _lastQueryKey && _state.error == null && !_state.isLoadingPage) {
      return;
    }
    _lastQueryKey = key;
    final token = ++_searchToken;
    _state = _state.copyWith(
      items: const [],
      page: 0,
      hasMore: true,
      isLoadingPage: false,
      clearError: true,
    );
    notifyListeners();
    await _loadPage(token);
  }

  /// Carica la pagina successiva (infinite-scroll). No-op mentre una pagina è in
  /// corso o non ci sono più risultati.
  Future<void> loadNextPage() => _loadPage(_searchToken);

  Future<void> _loadPage(int token) async {
    if (_state.isLoadingPage || !_state.hasMore) return;
    _state = _state.copyWith(isLoadingPage: true, clearError: true);
    notifyListeners();

    // Sovra-carico così le esclusioni lato client non lasciano buchi nella pagina.
    final requestSize = pageSize + _state.excluded.length;
    final result = await _searchSpecialists(
      text: _state.text,
      specialization: _state.specialization,
      city: _state.city,
      page: _state.page,
      pageSize: requestSize,
    );
    if (token != _searchToken) return; // soppiantata da una ricerca più recente

    result.fold(
      ok: (raw) {
        final filtered = raw
            .where((s) => !_state.excluded.contains(s.taxCode))
            .take(pageSize)
            .toList();
        _state = _state.copyWith(
          items: [..._state.items, ...filtered],
          isLoadingPage: false,
          firstPageDone: true,
          // Una pagina server piena di solito significa che c'è altro da caricare.
          hasMore: raw.length == requestSize,
          page: _state.page + 1,
        );
        notifyListeners();
      },
      err: (e) {
        _state = _state.copyWith(
            isLoadingPage: false, firstPageDone: true, error: e.message);
        notifyListeners();
      },
    );
  }

  /// Invia una richiesta di collegamento (single-flight). Al successo la card esce
  /// dalla lista (ora esclusa come pendente). Restituisce se è andata a buon fine.
  Future<bool> sendRequest(String specialistTaxCode, {String? message}) async {
    if (_sending) return false;
    _sending = true;
    final result = await _sendLinkRequest(specialistTaxCode, message: message);
    _sending = false;
    return result.fold(
      ok: (_) {
        _state = _state.copyWith(
          excluded: {..._state.excluded, specialistTaxCode},
          items: _state.items
              .where((s) => s.taxCode != specialistTaxCode)
              .toList(),
        );
        notifyListeners();
        return true;
      },
      err: (_) => false,
    );
  }

  /// Ritenta la fetch dello specialista collegato se il primo tentativo è fallito
  /// (rete), così l'avviso di sostituzione non si perde per un errore transitorio.
  Future<void> ensureLinkedSpecialistLoaded() async {
    if (_linkedFetchOk) return;
    await _loadLinkedSpecialist();
  }

  Future<void> _loadLinkedSpecialist() async {
    final result = await _getLinkedSpecialist();
    result.fold(
      ok: (specialist) {
        _linkedFetchOk = true;
        _state = specialist == null
            ? _state.copyWith(clearLinkedName: true)
            : _state.copyWith(
                linkedSpecialistName:
                    '${specialist.firstName} ${specialist.surname}');
        notifyListeners();
      },
      err: (_) => _linkedFetchOk = false,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
