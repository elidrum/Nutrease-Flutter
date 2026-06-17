import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../domain/model/food.dart';
import '../../../domain/model/meal.dart';
import '../../../domain/model/meal_food_item.dart';
import '../../../domain/model/meal_type.dart';
import '../../../domain/usecase/add_meal_use_case.dart';
import '../../../domain/usecase/get_meal_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../../domain/usecase/search_foods_use_case.dart';
import '../../../domain/usecase/update_meal_use_case.dart';

@immutable
class AddMealUiState {
  final Resource<List<Food>> searchResults;
  final String searchQuery;
  final List<MealFoodItem> selectedItems;
  final MealType type;
  final DateTime date;

  /// `HH:mm:ss` (formato della colonna `time` del DB).
  final String time;
  final bool isSaving;
  final String? error;
  final bool saved;
  final bool isEditing;

  /// True mentre il pasto esistente viene caricato per il prefill di modifica.
  final bool isLoadingExisting;

  const AddMealUiState({
    this.searchResults = const Success([]),
    this.searchQuery = '',
    this.selectedItems = const [],
    this.type = MealType.lunch,
    required this.date,
    required this.time,
    this.isSaving = false,
    this.error,
    this.saved = false,
    this.isEditing = false,
    this.isLoadingExisting = false,
  });

  AddMealUiState copyWith({
    Resource<List<Food>>? searchResults,
    String? searchQuery,
    List<MealFoodItem>? selectedItems,
    MealType? type,
    DateTime? date,
    String? time,
    bool? isSaving,
    String? error,
    bool? saved,
    bool? isEditing,
    bool? isLoadingExisting,
    bool clearError = false,
  }) =>
      AddMealUiState(
        searchResults: searchResults ?? this.searchResults,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedItems: selectedItems ?? this.selectedItems,
        type: type ?? this.type,
        date: date ?? this.date,
        time: time ?? this.time,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
        saved: saved ?? this.saved,
        isEditing: isEditing ?? this.isEditing,
        isLoadingExisting: isLoadingExisting ?? this.isLoadingExisting,
      );
}

/// ViewModel di aggiunta/modifica pasto (ricerca RF8 + submit RF9).
///
/// Il parametro `meal_id` della rotta decide la modalità (ADR-0013): `null`/`0` è
/// inserimento, `> 0` è modifica ([init] pre-compila via `GetMealUseCase`). La
/// ricerca è in debounce (300 ms) sul dataset in cache; [submit] è single-flight.
class AddMealViewModel extends ChangeNotifier {
  final SearchFoodsUseCase _searchFoodsUseCase;
  final AddMealUseCase _addMealUseCase;
  final UpdateMealUseCase _updateMealUseCase;
  final GetMealUseCase _getMealUseCase;
  final GetPatientFascicoloUseCase _getPatientFascicoloUseCase;

  /// Iniettabile così i test possono accorciare la finestra di debounce.
  final Duration debounceDuration;

  final int? _editingMealId;

  /// Fascicolo del pasto in modifica; evita di ri-risolverlo al submit.
  int? _fascicoloIdForEdit;

  Timer? _debounce;

  AddMealUiState _state;
  AddMealUiState get state => _state;

  AddMealViewModel({
    required this._searchFoodsUseCase,
    required this._addMealUseCase,
    required this._updateMealUseCase,
    required this._getMealUseCase,
    required this._getPatientFascicoloUseCase,
    int? mealId,
    DateTime? initialDate,
    this.debounceDuration = const Duration(milliseconds: 300),
  })  : _editingMealId = (mealId != null && mealId > 0) ? mealId : null,
        _state = AddMealUiState(
          date: initialDate ?? DateTime.now(),
          time: formatTime(DateTime.now()),
          isEditing: mealId != null && mealId > 0,
          isLoadingExisting: mealId != null && mealId > 0,
        );

  /// In modalità modifica, carica e pre-compila il pasto esistente.
  Future<void> init() async {
    final mealId = _editingMealId;
    if (mealId == null) return;
    final result = await _getMealUseCase(mealId);
    result.fold(
      ok: (meal) {
        _fascicoloIdForEdit = meal.fascicoloId;
        _set(_state.copyWith(
          isLoadingExisting: false,
          date: meal.date,
          time: meal.time,
          type: meal.type,
          selectedItems: meal.items,
        ));
      },
      err: (e) => _set(
          _state.copyWith(isLoadingExisting: false, error: e.message)),
    );
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _state = _state.copyWith(searchQuery: query);
    if (query.trim().isEmpty) {
      _set(_state.copyWith(searchResults: const Success([])));
      return;
    }
    notifyListeners();
    _debounce = Timer(debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    _set(_state.copyWith(searchResults: const Loading()));
    final result = await _searchFoodsUseCase(query);
    // Scarto le risposte stale se nel frattempo la query è cambiata.
    if (_state.searchQuery != query) return;
    result.fold(
      ok: (foods) => _set(_state.copyWith(searchResults: Success(foods))),
      err: (e) => _set(_state.copyWith(searchResults: Failure(e))),
    );
  }

  /// Aggiunge una riga alimento; ignora le quantità non positive (RF9). Pulisce la
  /// ricerca così il campo è pronto per l'alimento successivo.
  void addItem(Food food, double amount, String unit) {
    if (amount <= 0) return;
    _set(_state.copyWith(
      selectedItems: [
        ..._state.selectedItems,
        MealFoodItem(food: food, amount: amount, unit: unit),
      ],
      searchQuery: '',
      searchResults: const Success([]),
    ));
  }

  void removeItem(int index) {
    if (index < 0 || index >= _state.selectedItems.length) return;
    final items = [..._state.selectedItems]..removeAt(index);
    _set(_state.copyWith(selectedItems: items));
  }

  void setType(MealType type) => _set(_state.copyWith(type: type));

  void setDate(DateTime date) => _set(_state.copyWith(date: date));

  void setTime(String time) => _set(_state.copyWith(time: time));

  /// Salvataggio single-flight: sceglie insert o update dal parametro di rotta
  /// (ADR-0013) e risolve il fascicolo in inserimento.
  Future<void> submit() async {
    if (_state.isSaving) return;

    // Niente date future (come nel form dei sintomi).
    final now = DateTime.now();
    final selectedDay =
        DateTime(_state.date.year, _state.date.month, _state.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAfter(today)) {
      _set(_state.copyWith(error: ItStrings.errorFutureMealDate));
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

    final meal = Meal(
      id: _editingMealId,
      fascicoloId: fascicoloId,
      date: _state.date,
      time: _state.time,
      type: _state.type,
      items: _state.selectedItems,
    );

    final result = _editingMealId != null
        ? await _updateMealUseCase(meal)
        : await _addMealUseCase(meal);
    result.fold(
      ok: (_) => _set(_state.copyWith(isSaving: false, saved: true)),
      err: (e) => _set(_state.copyWith(isSaving: false, error: e.message)),
    );
  }

  void clearError() => _set(_state.copyWith(clearError: true));

  void _set(AddMealUiState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Formatta l'orario di un [DateTime] come `HH:mm:ss`.
  static String formatTime(DateTime dateTime) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dateTime.hour)}:${pad(dateTime.minute)}:00';
  }
}
