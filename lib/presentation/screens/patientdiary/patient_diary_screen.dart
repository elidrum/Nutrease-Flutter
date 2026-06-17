import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../domain/model/daily_diary.dart';
import '../../../domain/model/diary_date_range.dart';
import '../../../domain/model/meal.dart';
import '../../../domain/model/nutrient_filter.dart';
import '../../../domain/model/nutrient_totals.dart';
import '../../../domain/model/patient_diary_day.dart';
import '../../../domain/model/symptom.dart';
import '../../../domain/model/symptom_severity.dart';
import '../../../domain/usecase/get_patient_diary_range_use_case.dart';
import 'patient_diary_view_model.dart';

/// Diario paziente in sola lettura per lo specialista (RF19/RF20).
///
/// Niente FAB, menu o azioni di modifica/eliminazione (read-only, ADR-0016). Un
/// filtro di periodo (Oggi / 7g / 30g / Personalizzato, con cap a 92 giorni) guida
/// la fetch; un filtro nutriente **evidenzia** (non taglia mai) il valore
/// selezionato nelle card e nell'aggregato giornaliero.
class PatientDiaryScreen extends StatelessWidget {
  final int fascicoloId;
  final String patientName;

  const PatientDiaryScreen({
    super.key,
    required this.fascicoloId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PatientDiaryViewModel>(
      create: (ctx) => PatientDiaryViewModel(
        fascicoloId: fascicoloId,
        patientName: patientName,
        getRange: ctx.read<GetPatientDiaryRangeUseCase>(),
      )..load(),
      child: const _PatientDiaryView(),
    );
  }
}

/// Preset di periodo selezionabili da una chip.
enum _Period { today, last7, last30, custom }

class _PatientDiaryView extends StatefulWidget {
  const _PatientDiaryView();

  @override
  State<_PatientDiaryView> createState() => _PatientDiaryViewState();
}

class _PatientDiaryViewState extends State<_PatientDiaryView> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PatientDiaryViewModel>();
    final state = vm.state;

    // L'header dei filtri scorre col contenuto così niente va in overflow a scale
    // di font grandi; è l'item
    // 0 della lista.
    final header = _FilterHeader(
      period: _period,
      onPeriod: (period) => _onPeriodSelected(context, vm, period),
      filter: state.filter,
      onNutrient: vm.setNutrientFilter,
    );

    return Scaffold(
      appBar: AppBar(title: Text(ItStrings.patientDiaryTitle(state.patientName))),
      body: RefreshIndicator(
        onRefresh: vm.retry,
        child: switch (state.days) {
          Loading<List<PatientDiaryDay>>() =>
            _HeaderState(header: header, child: const LoadingView()),
          Failure<List<PatientDiaryDay>>(:final error) => _HeaderState(
              header: header,
              child: ErrorView(message: error.message, onRetry: vm.retry),
            ),
          Success<List<PatientDiaryDay>>(:final data) when data.isEmpty =>
            _HeaderState(
              header: header,
              child: const EmptyView(message: ItStrings.patientDiaryEmpty),
            ),
          Success<List<PatientDiaryDay>>(:final data) => ListView.builder(
              itemCount: data.length + 1,
              itemBuilder: (context, index) => index == 0
                  ? header
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingMd),
                      child: _DaySection(
                          day: data[index - 1], highlight: state.filter),
                    ),
            ),
        },
      ),
    );
  }

  Future<void> _onPeriodSelected(
      BuildContext context, PatientDiaryViewModel vm, _Period period) async {
    if (period == _Period.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(start: vm.state.range.from, end: now),
      );
      if (picked == null) return; // annullato: tengo la selezione corrente
      setState(() => _period = _Period.custom);
      vm.setRange(DiaryDateRange.custom(picked.start, picked.end));
      return;
    }

    setState(() => _period = period);
    vm.setRange(switch (period) {
      _Period.today => DiaryDateRange.today(),
      _Period.last7 => DiaryDateRange.last7(),
      _Period.last30 => DiaryDateRange.last30(),
      _Period.custom => DiaryDateRange.today(), // irraggiungibile
    });
  }
}

/// Chip dei preset di periodo (RF20). Wrap così la riga rifluisce a scale di font grandi.
class _PeriodFilterRow extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onSelect;

  const _PeriodFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd, vertical: AppTokens.spacingXs),
      child: Wrap(
        spacing: AppTokens.spacingSm,
        runSpacing: AppTokens.spacingXs,
        children: [
          for (final (period, label) in const [
            (_Period.today, ItStrings.periodToday),
            (_Period.last7, ItStrings.periodLast7),
            (_Period.last30, ItStrings.periodLast30),
            (_Period.custom, ItStrings.periodCustom),
          ])
            ChoiceChip(
              label: Text(label),
              selected: selected == period,
              selectedColor: AppTokens.appBarColor,
              onSelected: (_) => onSelect(period),
            ),
        ],
      ),
    );
  }
}

/// Chip di evidenziazione nutriente (RF20): solo evidenziazione, non tagliano mai la lista.
class _NutrientFilterRow extends StatelessWidget {
  final NutrientFilter selected;
  final ValueChanged<NutrientFilter> onSelect;

  const _NutrientFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd, vertical: AppTokens.spacingXs),
      child: Wrap(
        spacing: AppTokens.spacingSm,
        runSpacing: AppTokens.spacingXs,
        children: [
          for (final (filter, label) in const [
            (NutrientFilter.all, ItStrings.nutrientAll),
            (NutrientFilter.lactose, ItStrings.nutrientLactose),
            (NutrientFilter.sorbitol, ItStrings.nutrientSorbitol),
            (NutrientFilter.gluten, ItStrings.nutrientGluten),
            (NutrientFilter.kcal, ItStrings.nutrientKcal),
          ])
            ChoiceChip(
              label: Text(label),
              selected: selected == filter,
              selectedColor: AppTokens.appBarColor,
              onSelected: (_) => onSelect(filter),
            ),
        ],
      ),
    );
  }
}

/// Un giorno: header localizzato, l'aggregato nutrienti del giorno (evidenziato) e
/// la timeline mista pasti+sintomi (read-only).
class _DaySection extends StatelessWidget {
  final PatientDiaryDay day;
  final NutrientFilter highlight;

  const _DaySection({required this.day, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final header = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(day.date);
    // stretch → ogni card occupa tutta la larghezza (la card dei totali non ha un
    // suo Expanded interno, a differenza delle card pasto/sintomo).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
          child: Text(
            _capitalize(header),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (day.meals.isNotEmpty)
          _DayTotalsCard(totals: day.dayTotals, highlight: highlight),
        for (final entry in day.timeline)
          switch (entry) {
            MealEntry(:final meal) =>
              _ReadOnlyMealCard(meal: meal, highlight: highlight),
            SymptomEntry(:final symptom) =>
              _ReadOnlySymptomCard(symptom: symptom),
          },
        const SizedBox(height: AppTokens.spacingSm),
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _DayTotalsCard extends StatelessWidget {
  final NutrientTotals totals;
  final NutrientFilter highlight;

  const _DayTotalsCard({required this.totals, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      // Un po' più di spazio sotto, per staccare i totali dalle voci.
      margin: const EdgeInsets.only(bottom: AppTokens.spacingMd),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ItStrings.diaryDailyTotals,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            _NutrientTotalsLine(
              totals: totals,
              highlight: highlight,
              baseColor: scheme.onPrimaryContainer,
              fontSize: AppTokens.fontBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyMealCard extends StatelessWidget {
  final Meal meal;
  final NutrientFilter highlight;

  const _ReadOnlyMealCard({required this.meal, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = meal.totals ?? NutrientTotals.zero;
    final foods = meal.items.isEmpty
        ? ItStrings.offlineDetailUnavailable
        : meal.items.map((i) => i.food.name).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.restaurant, color: scheme.primary, semanticLabel: null),
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
                  _NutrientTotalsLine(
                    totals: totals,
                    highlight: highlight,
                    baseColor: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlySymptomCard extends StatelessWidget {
  final Symptom symptom;

  const _ReadOnlySymptomCard({required this.symptom});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context, symptom.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.healing, color: color, semanticLabel: null),
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
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

/// I quattro valori nutrienti come riga che rifluisce; quello in [highlight] è in
/// grassetto e tinto col colore primario (enfasi RF20, mai un filtro).
class _NutrientTotalsLine extends StatelessWidget {
  final NutrientTotals totals;
  final NutrientFilter highlight;
  final Color baseColor;
  final double fontSize;

  const _NutrientTotalsLine({
    required this.totals,
    required this.highlight,
    required this.baseColor,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = <(NutrientFilter, String)>[
      (NutrientFilter.lactose,
          '${ItStrings.nutrientLactose} ${totals.lactose.toStringAsFixed(1)} g'),
      (NutrientFilter.sorbitol,
          '${ItStrings.nutrientSorbitol} ${totals.sorbitol.toStringAsFixed(1)} g'),
      (NutrientFilter.gluten,
          '${ItStrings.nutrientGluten} ${totals.gluten.toStringAsFixed(1)} g'),
      (NutrientFilter.kcal, '${totals.kcal.toStringAsFixed(0)} kcal'),
    ];

    return Wrap(
      spacing: AppTokens.spacingMd,
      runSpacing: AppTokens.spacingXs,
      children: [
        for (final (filter, label) in parts)
          Builder(builder: (context) {
            final emphasized =
                highlight != NutrientFilter.all && highlight == filter;
            return Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: emphasized ? scheme.primary : baseColor,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
              ),
            );
          }),
      ],
    );
  }
}

/// Le chip dei filtri periodo/nutriente, impilate. Rese come primo item
/// scrollabile (o sopra gli stati loading/error/empty) così non affamano mai una
/// lista fissa a scale di font grandi.
class _FilterHeader extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onPeriod;
  final NutrientFilter filter;
  final ValueChanged<NutrientFilter> onNutrient;

  const _FilterHeader({
    required this.period,
    required this.onPeriod,
    required this.filter,
    required this.onNutrient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTokens.spacingSm),
        _PeriodFilterRow(selected: period, onSelect: onPeriod),
        _NutrientFilterRow(selected: filter, onSelect: onNutrient),
        const Divider(height: 1),
      ],
    );
  }
}

/// Uno stato loading / error / empty mostrato sotto l'[header], in una scroll view
/// che riempie la viewport così il `RefreshIndicator` può tirare e niente va in
/// overflow.
class _HeaderState extends StatelessWidget {
  final Widget header;
  final Widget child;

  const _HeaderState({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingXl),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
