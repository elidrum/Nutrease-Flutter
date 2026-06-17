import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_time_picker_row.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/model/symptom_severity.dart';
import '../../../domain/model/symptom_type.dart';
import '../../../domain/usecase/add_symptom_use_case.dart';
import '../../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../../domain/usecase/get_symptom_use_case.dart';
import '../../../domain/usecase/update_symptom_use_case.dart';
import 'add_symptom_view_model.dart';

/// Schermata di aggiunta/modifica sintomo (RF10). La stessa schermata serve
/// entrambe le modalità via il parametro di rotta `symptom_id` (ADR-0013).
class AddSymptomScreen extends StatelessWidget {
  final int? symptomId;
  final DateTime? initialDate;

  const AddSymptomScreen({super.key, this.symptomId, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddSymptomViewModel>(
      create: (ctx) => AddSymptomViewModel(
        addSymptomUseCase: ctx.read<AddSymptomUseCase>(),
        updateSymptomUseCase: ctx.read<UpdateSymptomUseCase>(),
        getSymptomUseCase: ctx.read<GetSymptomUseCase>(),
        getPatientFascicoloUseCase: ctx.read<GetPatientFascicoloUseCase>(),
        symptomId: symptomId,
        initialDate: initialDate,
      )..init(),
      child: const _AddSymptomView(),
    );
  }
}

class _AddSymptomView extends StatefulWidget {
  const _AddSymptomView();

  @override
  State<_AddSymptomView> createState() => _AddSymptomViewState();
}

class _AddSymptomViewState extends State<_AddSymptomView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddSymptomViewModel>();
    final state = vm.state;

    _handleOneShotEvents(vm);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing
            ? ItStrings.editSymptomTitle
            : ItStrings.addSymptomTitle),
      ),
      body: state.isLoadingExisting
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(ItStrings.symptomType),
                  const SizedBox(height: AppTokens.spacingSm),
                  _SymptomTypeDropdown(state: state, vm: vm),
                  if (state.type == SymptomType.other) ...[
                    const SizedBox(height: AppTokens.spacingMd),
                    _OtherTypeField(
                      initialValue: state.otherDescription,
                      onChanged: vm.setOtherDescription,
                    ),
                  ],
                  const SizedBox(height: AppTokens.spacingLg),
                  const SectionLabel(ItStrings.symptomSeverity),
                  const SizedBox(height: AppTokens.spacingSm),
                  _SeveritySelector(state: state, vm: vm),
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
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: FilledButton(
            onPressed: (state.isSaving || state.isLoadingExisting)
                ? null
                : vm.submit,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(ItStrings.saveSymptom),
          ),
        ),
      ),
    );
  }

  /// Mostra la conferma di salvataggio (poi fa pop) o una snackbar d'errore transitoria.
  void _handleOneShotEvents(AddSymptomViewModel vm) {
    final state = vm.state;
    if (state.saved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ItStrings.symptomSaved)),
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

class _SymptomTypeDropdown extends StatelessWidget {
  final AddSymptomUiState state;
  final AddSymptomViewModel vm;

  const _SymptomTypeDropdown({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SymptomType>(
      initialValue: state.type,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: AppTokens.fontBody,
            color: Theme.of(context).colorScheme.onSurface,
          ),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: [
        for (final type in SymptomType.values)
          DropdownMenuItem(
            value: type,
            child: Text(ItStrings.symptomTypeLabel(type)),
          ),
      ],
      onChanged: (type) {
        if (type != null) vm.setType(type);
      },
    );
  }
}

/// Campo testuale per un tipo di sintomo custom, mostrato quando si seleziona
/// "Altro". Il suo valore diventa la `Descrizione` che legge lo specialista (RF10).
class _OtherTypeField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _OtherTypeField({required this.initialValue, required this.onChanged});

  @override
  State<_OtherTypeField> createState() => _OtherTypeFieldState();
}

class _OtherTypeFieldState extends State<_OtherTypeField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLength: 100, // come sintomo.Descrizione varchar(100)
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: AppTokens.fontBody),
      decoration: const InputDecoration(
        labelText: ItStrings.symptomOtherFieldLabel,
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// Gravità come segmented control con le quattro etichette (Assente…Grave).
class _SeveritySelector extends StatelessWidget {
  final AddSymptomUiState state;
  final AddSymptomViewModel vm;

  const _SeveritySelector({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SymptomSeverity>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        textStyle: const TextStyle(fontSize: AppTokens.fontBody),
      ),
      segments: [
        // "Assente" è omesso di proposito: un sintomo registrato è sempre presente.
        for (final severity in SymptomSeverity.values
            .where((s) => s != SymptomSeverity.none))
          ButtonSegment(
            value: severity,
            label: Text(
              ItStrings.severityLabel(severity),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {state.severity},
      onSelectionChanged: (selected) => vm.setSeverity(selected.first),
    );
  }
}
