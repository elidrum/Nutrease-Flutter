import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../domain/model/password_policy.dart';
import '../../../domain/model/specialization_type.dart';
import '../../../domain/model/user_profile.dart';
import '../../../domain/usecase/change_password_use_case.dart';
import '../../../domain/usecase/delete_account_use_case.dart';
import '../../../domain/usecase/get_profile_use_case.dart';
import '../../../domain/usecase/logout_use_case.dart';
import '../../../domain/usecase/update_patient_use_case.dart';
import '../../../domain/usecase/update_specialist_use_case.dart';
import '../../navigation/routes.dart';
import 'profile_view_model.dart';

/// Schermata profilo (RF4–RF7): visualizza/modifica profilo, cambia password,
/// elimina account, logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (ctx) => ProfileViewModel(
        ctx.read<GetProfileUseCase>(),
        ctx.read<UpdatePatientUseCase>(),
        ctx.read<UpdateSpecialistUseCase>(),
        ctx.read<ChangePasswordUseCase>(),
        ctx.read<DeleteAccountUseCase>(),
        ctx.read<LogoutUseCase>(),
      )..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _vatNumber = TextEditingController();
  final _info = TextEditingController();
  SpecializationType? _specialization;
  bool _formInitialized = false;

  @override
  void dispose() {
    for (final c in [_firstName, _surname, _phone, _city, _vatNumber, _info]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Popola i controller modificabili una volta sola, dal primo profilo caricato.
  void _initForm(UserProfile profile) {
    if (_formInitialized) return;
    _formInitialized = true;
    final patient = profile.patient;
    final specialist = profile.specialist;
    if (patient != null) {
      _firstName.text = patient.firstName;
      _surname.text = patient.surname;
      _phone.text = patient.phone ?? '';
      _city.text = patient.city ?? '';
    } else if (specialist != null) {
      _firstName.text = specialist.firstName;
      _surname.text = specialist.surname;
      _vatNumber.text = specialist.vatNumber;
      _city.text = specialist.city ?? '';
      _info.text = specialist.info ?? '';
      _specialization = specialist.specialization;
    }
  }

  void _handleSideEffects(ProfileViewModel vm, ProfileUiState state) {
    if (state.navigateToLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.login);
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
    if (state.successMessage != null) {
      final message = state.successMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        vm.clearSuccess();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final state = vm.state;
    _handleSideEffects(vm, state);

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.profileTitle)),
      body: AsyncValueView<UserProfile>(
        resource: state.profile,
        onRetry: vm.load,
        onData: (profile) {
          _initForm(profile);
          return _content(context, vm, state, profile);
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ProfileViewModel vm,
    ProfileUiState state,
    UserProfile profile,
  ) {
    final email = profile.patient?.email ?? profile.specialist?.email ?? '';
    final isPatient = profile.patient != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadOnlyField(label: ItStrings.email, value: email),
          const SizedBox(height: AppTokens.spacingMd),
          _editField(_firstName, ItStrings.firstName, enabled: !state.isSaving),
          _editField(_surname, ItStrings.surname, enabled: !state.isSaving),
          if (isPatient) ...[
            _editField(_phone, 'Telefono', enabled: !state.isSaving),
            _editField(_city, ItStrings.city, enabled: !state.isSaving),
          ] else ...[
            _editField(_vatNumber, ItStrings.vatNumber,
                enabled: !state.isSaving),
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
              child: DropdownButtonFormField<SpecializationType>(
                initialValue: _specialization,
                decoration: const InputDecoration(
                  labelText: ItStrings.specialization,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in SpecializationType.values)
                    DropdownMenuItem(value: s, child: Text(s.dbLabel)),
                ],
                onChanged: state.isSaving
                    ? null
                    : (s) => setState(() => _specialization = s),
              ),
            ),
            _editField(_city, ItStrings.city, enabled: !state.isSaving),
            _editField(_info, 'Info', enabled: !state.isSaving),
          ],
          const SizedBox(height: AppTokens.spacingSm),
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () => _save(vm, profile, isPatient),
            child: state.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(ItStrings.save),
          ),
          const Divider(height: AppTokens.spacingXl),
          OutlinedButton(
            onPressed:
                state.isSaving ? null : () => _showChangePasswordDialog(vm),
            child: const Text(ItStrings.changePasswordTitle),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          OutlinedButton(
            onPressed: state.isSaving ? null : () => _showDeleteDialog(vm),
            child: const Text(ItStrings.deleteAccountTitle),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextButton(
            onPressed: state.isSaving ? null : vm.logout,
            child: const Text(ItStrings.logout),
          ),
        ],
      ),
    );
  }

  void _save(ProfileViewModel vm, UserProfile profile, bool isPatient) {
    if (isPatient) {
      vm.savePatient(profile.patient!.copyWith(
        firstName: _firstName.text.trim(),
        surname: _surname.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
      ));
    } else {
      vm.saveSpecialist(profile.specialist!.copyWith(
        firstName: _firstName.text.trim(),
        surname: _surname.text.trim(),
        vatNumber: _vatNumber.text.trim(),
        specialization: _specialization,
        city: _city.text.trim(),
        info: _info.text.trim(),
      ));
    }
  }

  Future<void> _showChangePasswordDialog(ProfileViewModel vm) async {
    final current = TextEditingController();
    final next = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final newError = next.text.isEmpty
                ? null
                : PasswordPolicy.validate(next.text);
            final canConfirm =
                current.text.isNotEmpty && next.text.isNotEmpty && newError == null;
            return AlertDialog(
              title: const Text(ItStrings.changePasswordTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: current,
                    obscureText: true,
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(
                      labelText: ItStrings.currentPassword,
                    ),
                  ),
                  TextField(
                    controller: next,
                    obscureText: true,
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      labelText: ItStrings.newPassword,
                      errorText: newError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(ItStrings.cancel),
                ),
                FilledButton(
                  onPressed: canConfirm
                      ? () {
                          Navigator.of(dialogContext).pop();
                          vm.changePassword(current.text, next.text);
                        }
                      : null,
                  child: const Text(ItStrings.confirm),
                ),
              ],
            );
          },
        );
      },
    );
    current.dispose();
    next.dispose();
  }

  Future<void> _showDeleteDialog(ProfileViewModel vm) async {
    final password = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final canConfirm = password.text.isNotEmpty;
            return AlertDialog(
              title: const Text(ItStrings.deleteAccountTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(ItStrings.deleteAccountWarning),
                  const SizedBox(height: AppTokens.spacingMd),
                  TextField(
                    controller: password,
                    obscureText: true,
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(
                      labelText: ItStrings.password,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(ItStrings.cancel),
                ),
                FilledButton(
                  onPressed: canConfirm
                      ? () {
                          Navigator.of(dialogContext).pop();
                          vm.deleteAccount(password.text);
                        }
                      : null,
                  child: const Text(ItStrings.delete),
                ),
              ],
            );
          },
        );
      },
    );
    password.dispose();
  }

  Widget _editField(
    TextEditingController controller,
    String label, {
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Un valore etichettato non modificabile (es. l'email, che RF5 vieta di cambiare).
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: false,
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
