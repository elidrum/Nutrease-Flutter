import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_scaffold_messenger.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/usecase/reset_password_use_case.dart';
import '../../navigation/routes.dart';
import 'reset_password_view_model.dart';

/// Schermata di completamento reset password: si inserisce il codice OTP a 8
/// cifre arrivato via email più una nuova password. Raggiunta da login →
/// "Password dimenticata?".
class ResetPasswordScreen extends StatelessWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ResetPasswordViewModel>(
      create: (ctx) => ResetPasswordViewModel(
        ctx.read<ResetPasswordUseCase>(),
        email: email,
      ),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureNew = true;
  bool _handledDone = false;

  static const int _codeLength = 8;

  @override
  void initState() {
    super.initState();
    // Rivaluta lo stato abilitato del bottone di submit mentre l'utente digita.
    for (final c in [_code, _newPassword, _confirm]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_code, _newPassword, _confirm]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _handleSideEffects(ResetPasswordViewModel vm, ResetPasswordUiState state) {
    if (state.done && !_handledDone) {
      _handledDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Messenger globale così la SnackBar sopravvive alla sostituzione di rotta.
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text(ItStrings.passwordResetDone)),
        );
        if (mounted) context.go(Routes.login);
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResetPasswordViewModel>();
    final state = vm.state;
    _handleSideEffects(vm, state);

    final canSubmit = _code.text.length == _codeLength &&
        _newPassword.text.isNotEmpty &&
        _confirm.text.isNotEmpty &&
        !state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.resetPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ItStrings.resetPasswordIntro(vm.email),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppTokens.spacingLg),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                enabled: !state.isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_codeLength),
                ],
                decoration: const InputDecoration(
                  labelText: ItStrings.resetCodeLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              TextField(
                controller: _newPassword,
                obscureText: _obscureNew,
                enabled: !state.isLoading,
                decoration: InputDecoration(
                  labelText: ItStrings.newPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    tooltip: _obscureNew
                        ? ItStrings.showPassword
                        : ItStrings.hidePassword,
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              TextField(
                controller: _confirm,
                obscureText: true,
                enabled: !state.isLoading,
                decoration: const InputDecoration(
                  labelText: ItStrings.confirmPassword,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTokens.spacingLg),
              FilledButton(
                onPressed: canSubmit
                    ? () => vm.submit(
                          code: _code.text,
                          newPassword: _newPassword.text,
                          confirmPassword: _confirm.text,
                        )
                    : null,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(ItStrings.resetPasswordButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
