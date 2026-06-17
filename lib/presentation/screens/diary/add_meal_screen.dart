import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_time_picker_row.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/model/food.dart';
import '../../../domain/model/meal_type.dart';
import '../../../domain/usecase/add_meal_use_case.dart';
import '../../../domain/usecase/get_meal_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../../domain/usecase/search_foods_use_case.dart';
import '../../../domain/usecase/update_meal_use_case.dart';
import 'add_meal_view_model.dart';

/// Schermata di aggiunta/modifica pasto (RF8 + RF9). La stessa schermata serve
/// entrambe le modalità via il parametro di rotta `meal_id` (ADR-0013).
class AddMealScreen extends StatelessWidget {
  final int? mealId;
  final DateTime? initialDate;

  const AddMealScreen({super.key, this.mealId, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddMealViewModel>(
      create: (ctx) => AddMealViewModel(
        searchFoodsUseCase: ctx.read<SearchFoodsUseCase>(),
        addMealUseCase: ctx.read<AddMealUseCase>(),
        updateMealUseCase: ctx.read<UpdateMealUseCase>(),
        getMealUseCase: ctx.read<GetMealUseCase>(),
        getPatientFascicoloUseCase: ctx.read<GetPatientFascicoloUseCase>(),
        mealId: mealId,
        initialDate: initialDate,
      )..init(),
      child: const _AddMealView(),
    );
  }
}

class _AddMealView extends StatefulWidget {
  const _AddMealView();

  @override
  State<_AddMealView> createState() => _AddMealViewState();
}

class _AddMealViewState extends State<_AddMealView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddMealViewModel>();
    final state = vm.state;

    // Il VM pulisce la query dopo l'aggiunta di un alimento: lo rispecchio nel campo.
    if (state.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    _handleOneShotEvents(vm);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            state.isEditing ? ItStrings.editMealTitle : ItStrings.addMealTitle),
      ),
      body: state.isLoadingExisting
          ? const LoadingView()
          : Column(
              children: [
                _MealHeaderForm(state: state, vm: vm),
                const SizedBox(height: AppTokens.spacingLg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMd),
                  child: TextField(
                    controller: _searchController,
                    onChanged: vm.onQueryChanged,
                    style: const TextStyle(fontSize: AppTokens.fontBody),
                    decoration: const InputDecoration(
                      hintText: ItStrings.searchFoodHint,
                      prefixIcon: Icon(Icons.search,
                          semanticLabel: ItStrings.searchIconLabel),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Expanded(
                  child: state.searchQuery.trim().isEmpty
                      ? _SelectedItemsList(state: state, vm: vm)
                      : _SearchResults(state: state, vm: vm),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: FilledButton(
            onPressed: (state.isSaving ||
                    state.isLoadingExisting ||
                    state.selectedItems.isEmpty)
                ? null
                : vm.submit,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(ItStrings.saveMeal),
          ),
        ),
      ),
    );
  }

  /// Mostra la conferma di salvataggio (poi fa pop) o una snackbar d'errore transitoria.
  void _handleOneShotEvents(AddMealViewModel vm) {
    final state = vm.state;
    if (state.saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ItStrings.mealSaved)),
        );
        context.pop();
      });
    } else if (state.error != null) {
      final message = state.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        vm.clearError();
      });
    }
  }
}

/// Selettori tipo pasto + data + ora (default: adesso).
class _MealHeaderForm extends StatelessWidget {
  final AddMealUiState state;
  final AddMealViewModel vm;

  const _MealHeaderForm({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(ItStrings.mealType),
          const SizedBox(height: AppTokens.spacingSm),
          DropdownButtonFormField<MealType>(
            initialValue: state.type,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: AppTokens.fontBody,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              for (final type in MealType.values)
                DropdownMenuItem(value: type, child: Text(type.dbValue)),
            ],
            onChanged: (type) {
              if (type != null) vm.setType(type);
            },
          ),
          const SizedBox(height: AppTokens.spacingLg),
          const SectionLabel(ItStrings.dateTimeLabel),
          const SizedBox(height: AppTokens.spacingSm),
          DateTimePickerRow(
            date: state.date,
            time: state.time,
            onDateChanged: vm.setDate,
            onTimeChanged: vm.setTime,
          ),
        ],
      ),
    );
  }
}

/// Risultati di ricerca in debounce; il tap aggiunge l'alimento.
class _SearchResults extends StatelessWidget {
  final AddMealUiState state;
  final AddMealViewModel vm;

  const _SearchResults({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return switch (state.searchResults) {
      Loading<List<Food>>() => const LoadingView(),
      Failure<List<Food>>(:final error) =>
        ErrorView(message: error.message),
      Success<List<Food>>(:final data) => data.isEmpty
          ? const EmptyView(message: ItStrings.noFoodsFound)
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final food = data[index];
                return ListTile(
                  // I nomi alimento arrivano a varchar(150): ellissi esplicita.
                  title: Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: food.category == null
                      ? null
                      : Text(
                          food.category!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    semanticLabel: ItStrings.addFoodIconLabel,
                  ),
                  onTap: () => _showAddFoodDialog(context, food),
                );
              },
            ),
    };
  }

  Future<void> _showAddFoodDialog(BuildContext context, Food food) async {
    final result = await showDialog<({double amount, String unit})>(
      context: context,
      builder: (_) => _AddFoodDialog(food: food),
    );
    if (result != null) vm.addItem(food, result.amount, result.unit);
  }
}

/// Picker quantità + unità con l'anteprima di conversione in grammi (RF8).
class _AddFoodDialog extends StatefulWidget {
  final Food food;

  const _AddFoodDialog({required this.food});

  @override
  State<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<_AddFoodDialog> {
  final TextEditingController _quantityController = TextEditingController();
  late String _unit = Food.unitGrams;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double? get _amount =>
      double.tryParse(_quantityController.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final isValid = amount != null && amount > 0;
    final gramsPreview = isValid && _unit != Food.unitGrams
        ? ItStrings.gramsPreview(
            widget.food.toGrams(amount, _unit).toStringAsFixed(1))
        : null;

    return AlertDialog(
      title: Text(
        widget.food.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _quantityController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: ItStrings.quantity,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          DropdownButtonFormField<String>(
            initialValue: _unit,
            decoration: const InputDecoration(
              labelText: ItStrings.unit,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final unit in widget.food.availableUnits())
                DropdownMenuItem(value: unit, child: Text(unit)),
            ],
            onChanged: (unit) {
              if (unit != null) setState(() => _unit = unit);
            },
          ),
          if (gramsPreview != null) ...[
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              gramsPreview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ItStrings.cancel),
        ),
        FilledButton(
          onPressed: isValid
              ? () =>
                  Navigator.of(context).pop((amount: amount, unit: _unit))
              : null,
          child: const Text(ItStrings.add),
        ),
      ],
    );
  }
}

/// Le righe del pasto composto (rimovibili prima del submit) con i grammi mostrati.
class _SelectedItemsList extends StatelessWidget {
  final AddMealUiState state;
  final AddMealViewModel vm;

  const _SelectedItemsList({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = state.selectedItems;
    if (items.isEmpty) {
      return const EmptyView(message: ItStrings.noSelectedFoods);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: SectionLabel(ItStrings.selectedFoods),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final grams = item.amountGrams.toStringAsFixed(1);
              final quantityLabel = item.unit == Food.unitGrams
                  ? '$grams g'
                  : '${item.amount.toStringAsFixed(1)} ${item.unit} '
                      '(${ItStrings.gramsPreview(grams)})';
              return ListTile(
                title: Text(
                  item.food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(quantityLabel),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: ItStrings.remove,
                  onPressed: () => vm.removeItem(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
