import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../domain/model/daily_diary.dart';
import '../../../domain/model/meal.dart';
import '../../../domain/model/nutrient_totals.dart';
import '../../../domain/model/symptom.dart';
import '../../../domain/model/symptom_severity.dart';
import '../../../domain/usecase/delete_meal_use_case.dart';
import '../../../domain/usecase/delete_symptom_use_case.dart';
import '../../../domain/usecase/get_daily_diary_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../navigation/app_router.dart';
import '../../navigation/routes.dart';
import 'diary_view_model.dart';

/// Timeline del diario giornaliero (RF11/RF12): lista mista pasti+sintomi di una
/// data, con navigazione per data, pull-to-refresh, aggiunta/modifica/eliminazione
/// e fallback su cache offline gestito nel data layer.
class DiaryScreen extends StatelessWidget {
  final DateTime? initialDate;

  const DiaryScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DiaryViewModel>(
      create: (ctx) => DiaryViewModel(
        getDailyDiaryUseCase: ctx.read<GetDailyDiaryUseCase>(),
        getPatientFascicoloUseCase: ctx.read<GetPatientFascicoloUseCase>(),
        deleteMealUseCase: ctx.read<DeleteMealUseCase>(),
        deleteSymptomUseCase: ctx.read<DeleteSymptomUseCase>(),
        initialDate: initialDate,
      )..refresh(),
      child: const _DiaryView(),
    );
  }
}

class _DiaryView extends StatefulWidget {
  const _DiaryView();

  @override
  State<_DiaryView> createState() => _DiaryViewState();
}

/// [RouteAware] così il diario ricarica quando le schermate di aggiunta/modifica
/// tornano indietro (equivalente ADR-0014), senza affidarsi a un risultato di
/// navigazione.
class _DiaryViewState extends State<_DiaryView> with RouteAware {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      if (_route != null) diaryRouteObserver.unsubscribe(this);
      _route = route;
      diaryRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Tornati da aggiunta/modifica: ricarico così una voce appena salvata compare.
    context.read<DiaryViewModel>().refresh();
  }

  @override
  void dispose() {
    diaryRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiaryViewModel>();
    final state = vm.state;

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.diaryTitle)),
      floatingActionButton: _AddEntryFab(date: state.selectedDate),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          _DateNavigator(
            date: state.selectedDate,
            onPrev: () => vm.selectDate(
                state.selectedDate.subtract(const Duration(days: 1))),
            onNext: () => vm.selectDate(
                state.selectedDate.add(const Duration(days: 1))),
            onPickDate: () => _pickDate(context, vm),
          ),
          Expanded(
            child: switch (state.diary) {
              Loading<DailyDiary>() => const LoadingView(),
              Failure<DailyDiary>(:final error) => RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: _ScrollableMessage(
                    child: ErrorView(
                        message: error.message, onRetry: vm.refresh),
                  ),
                ),
              Success<DailyDiary>(:final data) =>
                _DiaryContent(diary: data, vm: vm),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DiaryViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) vm.selectDate(picked);
  }
}

/// Header dei totali giornalieri (quando ci sono pasti) + la lista timeline fusa.
class _DiaryContent extends StatelessWidget {
  final DailyDiary diary;
  final DiaryViewModel vm;

  const _DiaryContent({required this.diary, required this.vm});

  @override
  Widget build(BuildContext context) {
    final entries = diary.timeline;
    return Column(
      children: [
        if (diary.meals.isNotEmpty) _DailyTotalsCard(totals: diary.totals),
        Expanded(
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            child: entries.isEmpty
                ? _ScrollableMessage(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingXl,
                        vertical: AppTokens.spacingLg,
                      ),
                      child: Text(
                        ItStrings.diaryEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: AppTokens.fontSubtitle,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        _entryCard(context, entries[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _entryCard(BuildContext context, DiaryEntry entry) {
    return switch (entry) {
      MealEntry(:final meal) => _DismissibleEntry(
          dismissKey: ValueKey('meal-${meal.id}'),
          confirmMessage: ItStrings.confirmDeleteMeal,
          deletedMessage: ItStrings.mealDeleted,
          onDelete: () => vm.deleteMeal(meal.id!),
          child: _MealCard(
            meal: meal,
            onEdit: () => _openEditMeal(context, meal),
            onDelete: () => _confirmAndDelete(
              context,
              message: ItStrings.confirmDeleteMeal,
              deletedMessage: ItStrings.mealDeleted,
              onDelete: () => vm.deleteMeal(meal.id!),
            ),
          ),
        ),
      SymptomEntry(:final symptom) => _DismissibleEntry(
          dismissKey: ValueKey('symptom-${symptom.id}'),
          confirmMessage: ItStrings.confirmDeleteSymptom,
          deletedMessage: ItStrings.symptomDeleted,
          onDelete: () => vm.deleteSymptom(symptom.id!),
          child: _SymptomCard(
            symptom: symptom,
            onEdit: () => _openEditSymptom(context, symptom),
            onDelete: () => _confirmAndDelete(
              context,
              message: ItStrings.confirmDeleteSymptom,
              deletedMessage: ItStrings.symptomDeleted,
              onDelete: () => vm.deleteSymptom(symptom.id!),
            ),
          ),
        ),
    };
  }

  void _openEditMeal(BuildContext context, Meal meal) {
    context.push(_routeWithParams(Routes.addMeal, {
      'meal_id': '${meal.id}',
      'date': diary.date.toIso8601String(),
    }));
  }

  void _openEditSymptom(BuildContext context, Symptom symptom) {
    context.push(_routeWithParams(Routes.addSymptom, {
      'symptom_id': '${symptom.id}',
      'date': diary.date.toIso8601String(),
    }));
  }
}

/// Dialog di conferma + delete + SnackBar di feedback (usato dal percorso del menu "…").
Future<void> _confirmAndDelete(
  BuildContext context, {
  required String message,
  required String deletedMessage,
  required Future<bool> Function() onDelete,
}) async {
  final confirmed = await _showConfirmDialog(context, message);
  if (confirmed != true) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await onDelete();
  messenger.showSnackBar(SnackBar(
    content: Text(ok ? deletedMessage : ItStrings.errorGeneric),
  ));
}

Future<bool?> _showConfirmDialog(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(ItStrings.confirmDeleteTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(ItStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(ItStrings.delete),
        ),
      ],
    ),
  );
}

String _routeWithParams(String path, Map<String, String> params) =>
    Uri(path: path, queryParameters: params).toString();

/// Avvolge la card di una voce in un [Dismissible] per lo swipe-to-delete:
/// [Key] univoca, un dialog di conferma in `confirmDismiss` e una SnackBar di
/// feedback.
class _DismissibleEntry extends StatelessWidget {
  final Key dismissKey;
  final String confirmMessage;
  final String deletedMessage;
  final Future<bool> Function() onDelete;
  final Widget child;

  const _DismissibleEntry({
    required this.dismissKey,
    required this.confirmMessage,
    required this.deletedMessage,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showConfirmDialog(context, confirmMessage),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await onDelete();
        messenger.showSnackBar(SnackBar(
          content: Text(ok ? deletedMessage : ItStrings.errorGeneric),
        ));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
        margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      child: child,
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const _DateNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('dd/MM/yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingSm, vertical: AppTokens.spacingXs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: ItStrings.diaryPreviousDay,
            onPressed: onPrev,
          ),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: AppTokens.iconSm),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // TextStyle nudo (senza colore) così traspare il foreground del
                // TextButton; alzo solo dimensione/peso per parità coi sottotitoli
                // della home.
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppTokens.fontSubtitle,
                ),
              ),
              onPressed: onPickDate,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: ItStrings.diaryNextDay,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _DailyTotalsCard extends StatelessWidget {
  final NutrientTotals totals;

  const _DailyTotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd, vertical: AppTokens.spacingSm),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ItStrings.diaryDailyTotals,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              ItStrings.mealTotalsLine(
                lactose: totals.lactose.toStringAsFixed(1),
                sorbitol: totals.sorbitol.toStringAsFixed(1),
                gluten: totals.gluten.toStringAsFixed(1),
                kcal: totals.kcal.toStringAsFixed(0),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = meal.totals ?? NutrientTotals.zero;
    final foods = meal.items.isEmpty
        ? ItStrings.offlineDetailUnavailable
        : meal.items.map((i) => i.food.name).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.restaurant, color: scheme.primary),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(
                      title: meal.type.dbValue,
                      time: meal.time.substring(0, 5),
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      foods,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      ItStrings.mealTotalsLine(
                        lactose: totals.lactose.toStringAsFixed(1),
                        sorbitol: totals.sorbitol.toStringAsFixed(1),
                        gluten: totals.gluten.toStringAsFixed(1),
                        kcal: totals.kcal.toStringAsFixed(0),
                      ),
                      style: TextStyle(color: scheme.primary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _EntryMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  final Symptom symptom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SymptomCard({
    required this.symptom,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context, symptom.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.healing, color: color),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(
                      title: ItStrings.symptomDisplayLabel(symptom),
                      time: symptom.time.substring(0, 5),
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      ItStrings.severityLabel(symptom.severity),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _EntryMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }

  /// Gravità → colore del tema (come il porting Android).
  static Color _severityColor(BuildContext context, SymptomSeverity severity) {
    final scheme = Theme.of(context).colorScheme;
    return switch (severity) {
      SymptomSeverity.none => scheme.onSurfaceVariant,
      SymptomSeverity.mild => scheme.tertiary,
      SymptomSeverity.moderate => scheme.secondary,
      SymptomSeverity.severe => scheme.error,
    };
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final String time;

  const _CardHeader({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(time, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Il menu "…" con Modifica/Elimina (RF12), in aggiunta al gesto di swipe.
class _EntryMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_EntryAction>(
      icon: const Icon(Icons.more_vert, semanticLabel: ItStrings.entryActionsLabel),
      onSelected: (action) => switch (action) {
        _EntryAction.edit => onEdit(),
        _EntryAction.delete => onDelete(),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _EntryAction.edit, child: Text(ItStrings.edit)),
        PopupMenuItem(
            value: _EntryAction.delete, child: Text(ItStrings.delete)),
      ],
    );
  }
}

enum _EntryAction { edit, delete }

/// Un FAB il cui menu offre "Aggiungi pasto" / "Aggiungi sintomo".
class _AddEntryFab extends StatelessWidget {
  final DateTime date;

  const _AddEntryFab({required this.date});

  @override
  Widget build(BuildContext context) {
    // Righe larghe e di pari larghezza così il popup sembra più grande e si legge bene.
    const itemStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(AppTokens.menuWidth, AppTokens.menuItemHeight),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: AppTokens.fontSubtitle),
      ),
    );
    return MenuAnchor(
      // Centro il menu sopra il FAB (centrato): di default il pannello si allinea
      // al bordo sinistro del FAB, quindi lo sposto a sinistra di metà differenza
      // di larghezza e lo sollevo un po' dal bottone.
      alignmentOffset: const Offset(
        -(AppTokens.menuWidth - AppTokens.fabSize) / 2,
        AppTokens.spacingSm,
      ),
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
        ),
      ),
      builder: (context, controller, child) => Theme(
        // Dimensione FAB custom, via di mezzo tra lo standard M3 (56) e il large
        // (96): impostata via sizeConstraints del tema (non esiste un parametro size).
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme:
              Theme.of(context).floatingActionButtonTheme.copyWith(
                    sizeConstraints: const BoxConstraints.tightFor(
                      width: AppTokens.fabSize,
                      height: AppTokens.fabSize,
                    ),
                  ),
        ),
        child: FloatingActionButton(
          tooltip: ItStrings.diaryAddEntry,
          shape: const CircleBorder(),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: const Icon(Icons.add, size: AppTokens.iconMd),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          style: itemStyle,
          leadingIcon: const Icon(Icons.restaurant, size: AppTokens.iconMd),
          onPressed: () => context.push(_routeWithParams(
              Routes.addMeal, {'date': date.toIso8601String()})),
          child: const Text(ItStrings.diaryAddMeal),
        ),
        MenuItemButton(
          style: itemStyle,
          leadingIcon: const Icon(Icons.healing, size: AppTokens.iconMd),
          onPressed: () => context.push(_routeWithParams(
              Routes.addSymptom, {'date': date.toIso8601String()})),
          child: const Text(ItStrings.diaryAddSymptom),
        ),
      ],
    );
  }
}

/// Rende "pullabile" un messaggio non scrollabile per il `RefreshIndicator`.
class _ScrollableMessage extends StatelessWidget {
  final Widget child;

  const _ScrollableMessage({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
