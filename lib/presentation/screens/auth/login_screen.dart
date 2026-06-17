import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/model/user_role.dart';
import '../../../domain/usecase/login_use_case.dart';
import '../../../domain/usecase/send_password_reset_use_case.dart';
import '../../navigation/routes.dart';
import 'auth_view_model.dart';

/// Schermata di login (RF3). Sostituisce il placeholder dello sprint 1.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (ctx) => AuthViewModel(
        ctx.read<LoginUseCase>(),
        ctx.read<SendPasswordResetUseCase>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSideEffects(AuthViewModel vm, LoginUiState state) {
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
    if (state.passwordResetSent) {
      final email = _emailController.text.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        vm.consumePasswordResetSent();
        // Il codice OTP è arrivato via email; vai a inserirlo con la nuova password.
        context.push(
          '${Routes.resetPassword}?email=${Uri.encodeComponent(email)}',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final state = vm.state;
    _handleSideEffects(vm, state);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ItStrings.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTokens.fontDisplay,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  ItStrings.appSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: AppTokens.fontBody,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingXl),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !state.isLoading,
                  // Rebuild così il bottone "Accedi" si abilita appena si digita un'email.
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: AppTokens.fontSubtitle),
                  decoration: const InputDecoration(
                    labelText: ItStrings.email,
                    labelStyle: TextStyle(fontSize: AppTokens.fontBody),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingLg),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !state.isLoading,
                  onSubmitted: (_) => vm.login(
                    _emailController.text,
                    _passwordController.text,
                  ),
                  style: const TextStyle(fontSize: AppTokens.fontSubtitle),
                  decoration: InputDecoration(
                    labelText: ItStrings.password,
                    labelStyle:
                        const TextStyle(fontSize: AppTokens.fontBody),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      tooltip: _obscurePassword
                          ? ItStrings.showPassword
                          : ItStrings.hidePassword,
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingLg),
                FilledButton(
                  onPressed:
                      (state.isLoading || _emailController.text.trim().isEmpty)
                          ? null
                          : () => vm.login(
                                _emailController.text,
                                _passwordController.text,
                              ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(ItStrings.loginButton),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                TextButton(
                  onPressed: state.isSendingReset
                      ? null
                      : () => vm.sendPasswordReset(_emailController.text),
                  child: const Text(ItStrings.forgotPassword),
                ),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context.push(Routes.register),
                  child: const Text(ItStrings.goToRegister),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
