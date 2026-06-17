import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/home_action_card.dart';
import '../../../domain/model/specialist.dart';
import '../../../domain/usecase/get_linked_specialist_use_case.dart';
import '../../navigation/app_router.dart';
import '../../navigation/routes.dart';
import 'home_scaffold.dart';
import 'patient_home_view_model.dart';

/// Shell della home paziente (landing RF3). Mostra in cima la card dello
/// specialista collegato (delta Android 2026-06-12), poi le voci di funzionalità.
class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => HomeScaffold(
        title: ItStrings.patientHomeTitle,
        subtitle: ItStrings.patientHomeSubtitle,
        featureEntries: [
          const _LinkedSpecialistCard(),
          Builder(
            builder: (context) => HomeActionCard(
              title: ItStrings.diaryAction,
              subtitle: ItStrings.diarySubtitle,
              icon: Icons.menu_book,
              iconSemanticLabel: ItStrings.diaryIconLabel,
              onTap: () => context.push(Routes.diary),
            ),
          ),
          Builder(
            builder: (context) => HomeActionCard(
              title: ItStrings.findSpecialistAction,
              subtitle: ItStrings.findSpecialistSubtitle,
              icon: Icons.search,
              iconSemanticLabel: ItStrings.findSpecialistIconLabel,
              onTap: () => context.push(Routes.specialists),
            ),
          ),
        ],
      );
}

/// Card "Il tuo specialista" autonoma: possiede un [PatientHomeViewModel] e si
/// ricarica quando la home torna in focus (ADR-0014), così la card si aggiorna
/// dopo un flusso di richiesta senza toccare l'[HomeScaffold] condiviso.
class _LinkedSpecialistCard extends StatelessWidget {
  const _LinkedSpecialistCard();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PatientHomeViewModel>(
      create: (ctx) =>
          PatientHomeViewModel(ctx.read<GetLinkedSpecialistUseCase>())
            ..refresh(),
      child: const _LinkedSpecialistCardBody(),
    );
  }
}

class _LinkedSpecialistCardBody extends StatefulWidget {
  const _LinkedSpecialistCardBody();

  @override
  State<_LinkedSpecialistCardBody> createState() =>
      _LinkedSpecialistCardBodyState();
}

class _LinkedSpecialistCardBodyState extends State<_LinkedSpecialistCardBody>
    with RouteAware {
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
    // Tornati in home (es. dopo aver inviato una richiesta): ri-controllo il collegamento.
    context.read<PatientHomeViewModel>().refresh();
  }

  @override
  void dispose() {
    diaryRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PatientHomeViewModel>().state;

    // Niente flicker prima che il primo caricamento si risolva.
    if (!state.isLinkedSpecialistLoaded) return const SizedBox.shrink();

    final specialist = state.linkedSpecialist;
    return specialist == null
        ? const _NoSpecialistCard()
        : _SpecialistCard(specialist: specialist);
  }
}

class _SpecialistCard extends StatelessWidget {
  final Specialist specialist;

  const _SpecialistCard({required this.specialist});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            Icon(Icons.medical_services,
                size: AppTokens.iconMd,
                color: scheme.onPrimaryContainer,
                semanticLabel: ItStrings.specialistIconLabel),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ItStrings.patientHomeLinkedSpecialistLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontSize: AppTokens.fontBody,
                        ),
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  Text(
                    '${specialist.firstName} ${specialist.surname}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: AppTokens.fontTitle,
                        ),
                  ),
                  if (specialist.specialization != null)
                    Text(
                      specialist.specialization!.dbLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontSize: AppTokens.fontBody,
                          ),
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

class _NoSpecialistCard extends StatelessWidget {
  const _NoSpecialistCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => context.push(Routes.specialists),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            children: [
              Icon(Icons.person_search,
                  size: AppTokens.iconMd,
                  color: scheme.onSurfaceVariant,
                  semanticLabel: ItStrings.findSpecialistIconLabel),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ItStrings.patientHomeNoSpecialistTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: AppTokens.fontTitle,
                          ),
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      ItStrings.patientHomeNoSpecialistSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: AppTokens.fontBody,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
