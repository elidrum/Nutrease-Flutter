import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/model/gender.dart';
import '../../../domain/model/specialization_type.dart';
import '../../../domain/model/user_role.dart';
import '../../../domain/usecase/register_use_case.dart';
import '../../navigation/routes.dart';
import 'date_slash_input_formatter.dart';
import 'register_view_model.dart';

/// Schermata di registrazione (RF1/RF2). Sostituisce la rotta placeholder dello sprint 1.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (ctx) => RegisterViewModel(ctx.read<RegisterUseCase>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  // Campi comuni.
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _taxCode = TextEditingController();
  // Solo paziente.
  final _birthDate = TextEditingController();
  Gender? _gender;
  // Solo specialista.
  final _vatNumber = TextEditingController();
  final _city = TextEditingController();
  SpecializationType? _specialization;

  @override
  void dispose() {
    for (final c in [
      _email,
      _password,
      _firstName,
      _surname,
      _taxCode,
      _birthDate,
      _vatNumber,
      _city,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSideEffects(RegisterViewModel vm, RegisterUiState state) {
    if (state.navigateTo != null) {
      final role = state.navigateTo!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        vm.consumeNavigation();
        context.go(role == UserRole.patient
            ? Routes.patientHome
            : Routes.specialistHome);
      });
    }
    if (state.error != null) {
      final message = state.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        vm.clearError();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  void _submit(RegisterViewModel vm, RegisterTab tab) {
    if (tab == RegisterTab.patient) {
      vm.submitPatient(
        email: _email.text,
        password: _password.text,
        firstName: _firstName.text,
        surname: _surname.text,
        taxCode: _taxCode.text,
        gender: _gender,
        birthDateText: _birthDate.text,
      );
    } else {
      vm.submitSpecialist(
        email: _email.text,
        password: _password.text,
        firstName: _firstName.text,
        surname: _surname.text,
        taxCode: _taxCode.text,
        vatNumber: _vatNumber.text,
        specialization: _specialization,
        city: _city.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    final state = vm.state;
    _handleSideEffects(vm, state);

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.registerTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<RegisterTab>(
                segments: const [
                  ButtonSegment(
                    value: RegisterTab.patient,
                    label: Text(ItStrings.tabPatient),
                  ),
                  ButtonSegment(
                    value: RegisterTab.specialist,
                    label: Text(ItStrings.tabSpecialist),
                  ),
                ],
                selected: {state.tab},
                onSelectionChanged: state.isLoading
                    ? null
                    : (selection) => vm.selectTab(selection.first),
              ),
              const SizedBox(height: AppTokens.spacingLg),
              _field(state, _firstName, ItStrings.firstName,
                  errorKey: RegisterField.firstName),
              _field(state, _surname, ItStrings.surname,
                  errorKey: RegisterField.surname),
              _field(state, _taxCode, ItStrings.taxCode,
                  errorKey: RegisterField.taxCode,
                  capitalization: TextCapitalization.characters),
              _field(state, _email, ItStrings.email,
                  errorKey: RegisterField.email,
                  keyboard: TextInputType.emailAddress),
              _field(state, _password, ItStrings.password,
                  errorKey: RegisterField.password, obscure: true),
              if (state.tab == RegisterTab.patient)
                ..._patientFields(state)
              else
                ..._specialistFields(state),
              const SizedBox(height: AppTokens.spacingMd),
              FilledButton(
                onPressed:
                    state.isLoading ? null : () => _submit(vm, state.tab),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(ItStrings.registerButton),
              ),
              TextButton(
                onPressed: state.isLoading ? null : () => context.pop(),
                child: const Text(ItStrings.goToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _patientFields(RegisterUiState state) => [
        _field(
          state,
          _birthDate,
          ItStrings.birthDate,
          errorKey: RegisterField.birthDate,
          hint: ItStrings.birthDateHint,
          keyboard: TextInputType.number,
          formatters: [DateSlashInputFormatter()],
        ),
        _GenderSelector(
          value: _gender,
          enabled: !state.isLoading,
          error: state.fieldErrors[RegisterField.gender],
          onChanged: (g) => setState(() => _gender = g),
        ),
        const SizedBox(height: AppTokens.spacingMd),
      ];

  List<Widget> _specialistFields(RegisterUiState state) => [
        _field(state, _vatNumber, ItStrings.vatNumber,
            errorKey: RegisterField.vatNumber,
            keyboard: TextInputType.number),
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
          child: DropdownButtonFormField<SpecializationType>(
            initialValue: _specialization,
            decoration: InputDecoration(
              labelText: ItStrings.specialization,
              border: const OutlineInputBorder(),
              errorText: state.fieldErrors[RegisterField.specialization],
            ),
            items: [
              for (final s in SpecializationType.values)
                DropdownMenuItem(value: s, child: Text(s.dbLabel)),
            ],
            onChanged: state.isLoading
                ? null
                : (s) => setState(() => _specialization = s),
          ),
        ),
        _field(state, _city, ItStrings.city, errorKey: RegisterField.city),
      ];

  Widget _field(
    RegisterUiState state,
    TextEditingController controller,
    String label, {
    String? errorKey,
    bool obscure = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textCapitalization: capitalization,
        autocorrect: false,
        enabled: !state.isLoading,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          errorText: errorKey == null ? null : state.fieldErrors[errorKey],
        ),
      ),
    );
  }
}

/// Selettore M / F / Altro con messaggio d'errore inline.
class _GenderSelector extends StatelessWidget {
  final Gender? value;
  final bool enabled;
  final String? error;
  final ValueChanged<Gender> onChanged;

  const _GenderSelector({
    required this.value,
    required this.enabled,
    required this.error,
    required this.onChanged,
  });

  static const _labels = {
    Gender.male: ItStrings.genderMale,
    Gender.female: ItStrings.genderFemale,
    Gender.other: ItStrings.genderOther,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ItStrings.gender, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTokens.spacingXs),
        Wrap(
          spacing: AppTokens.spacingSm,
          children: [
            for (final g in Gender.values)
              ChoiceChip(
                label: Text(_labels[g]!),
                selected: value == g,
                onSelected: enabled ? (_) => onChanged(g) : null,
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingXs),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
