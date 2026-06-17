import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../domain/usecase/get_profile_use_case.dart';
import '../../../domain/usecase/logout_use_case.dart';
import '../../navigation/routes.dart';
import 'home_view_model.dart';

/// Shell minimale della home condivisa dai due ruoli: saluto + sottotitolo, card
/// di funzionalità specifiche del ruolo, e le azioni Profilo + Logout nell'app bar.
///
/// Ogni schermata di ruolo la fornisce con i propri [title], [subtitle] e
/// [featureEntries] (es. la card "Aggiungi pasto" del paziente).
class HomeScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> featureEntries;

  const HomeScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.featureEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) => HomeViewModel(
        ctx.read<GetProfileUseCase>(),
        ctx.read<LogoutUseCase>(),
      )..load(),
      child: _HomeView(
        title: title,
        subtitle: subtitle,
        featureEntries: featureEntries,
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> featureEntries;

  const _HomeView({
    required this.title,
    required this.subtitle,
    required this.featureEntries,
  });

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (vm.navigateToLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.login);
      });
    }

    return Scaffold(
      appBar: AppBar(
        // La home tiene il titolo allineato a sinistra col contenuto (stesso
        // inset sinistro del saluto "Ciao, …"); ogni altra schermata lo centra.
        centerTitle: false,
        titleSpacing: AppTokens.spacingLg,
        // La home tiene il titolo più grande; le altre usano la dimensione del tema.
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: AppTokens.fontHomeAppBarTitle),
        ),
        // Rientro le azioni così i glifi delle icone stanno allo stesso inset
        // destro: il glifo di un IconButton è ~12px dentro il suo box da 48px,
        // quindi 12px di padding finale portano il glifo a 24px dal bordo,
        // speculare al titolo.
        actionsPadding: const EdgeInsets.only(right: AppTokens.appBarActionInset),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: ItStrings.profileAction,
            onPressed: () => context.push(Routes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: ItStrings.logout,
            onPressed: vm.logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spacingLg,
          AppTokens.spacingXl,
          AppTokens.spacingLg,
          AppTokens.spacingLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AsyncValueView<String>(
              resource: vm.name,
              onRetry: vm.load,
              onData: (name) => Text(
                ItStrings.greeting(name),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTokens.fontDisplay,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: AppTokens.fontSubtitle,
                  ),
            ),
            const SizedBox(height: AppTokens.spacingXl),
            for (final entry in widget.featureEntries) ...[
              entry,
              const SizedBox(height: AppTokens.spacingMd),
            ],
          ],
        ),
      ),
    );
  }
}
