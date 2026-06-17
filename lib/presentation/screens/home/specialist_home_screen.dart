import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/widgets/home_action_card.dart';
import '../../../domain/usecase/accept_link_request_use_case.dart';
import '../../../domain/usecase/get_received_link_requests_use_case.dart';
import '../../../domain/usecase/reject_link_request_use_case.dart';
import '../../navigation/app_router.dart';
import '../../navigation/routes.dart';
import '../requests/link_requests_view_model.dart';
import 'home_scaffold.dart';

/// Shell della home specialista (landing RF3). Aggiunge la voce "I miei pazienti"
/// (RF18) e la voce "Richieste di collegamento" con badge del conteggio pendenti
/// (RF15).
class SpecialistHomeScreen extends StatelessWidget {
  const SpecialistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScaffold(
        title: ItStrings.specialistHomeTitle,
        subtitle: ItStrings.specialistHomeSubtitle,
        featureEntries: [_LinkedPatientsEntry(), _LinkRequestsEntry()],
      );
}

/// Apre la lista dei pazienti collegati dello specialista (RF18).
class _LinkedPatientsEntry extends StatelessWidget {
  const _LinkedPatientsEntry();

  @override
  Widget build(BuildContext context) {
    return HomeActionCard(
      title: ItStrings.linkedPatientsAction,
      subtitle: ItStrings.linkedPatientsSubtitle,
      icon: Icons.groups,
      iconSemanticLabel: ItStrings.patientsIconLabel,
      onTap: () => context.push(Routes.linkedPatients),
    );
  }
}

/// Bottone "Richieste di collegamento" autonomo: possiede un
/// [LinkRequestsViewModel] solo per esporre [pendingCount] come badge, e ricarica
/// il conteggio quando la home torna in focus (ADR-0014).
class _LinkRequestsEntry extends StatelessWidget {
  const _LinkRequestsEntry();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LinkRequestsViewModel>(
      create: (ctx) => LinkRequestsViewModel(
        getReceived: ctx.read<GetReceivedLinkRequestsUseCase>(),
        accept: ctx.read<AcceptLinkRequestUseCase>(),
        reject: ctx.read<RejectLinkRequestUseCase>(),
      )..load(),
      child: const _LinkRequestsEntryBody(),
    );
  }
}

class _LinkRequestsEntryBody extends StatefulWidget {
  const _LinkRequestsEntryBody();

  @override
  State<_LinkRequestsEntryBody> createState() => _LinkRequestsEntryBodyState();
}

class _LinkRequestsEntryBodyState extends State<_LinkRequestsEntryBody>
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
    // Tornati dalla inbox: ricarico il conteggio pendenti (una potrebbe essere
    // stata accettata/rifiutata).
    context.read<LinkRequestsViewModel>().load();
  }

  @override
  void dispose() {
    diaryRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<LinkRequestsViewModel>().pendingCount;
    return HomeActionCard(
      title: ItStrings.linkRequestsAction,
      subtitle: ItStrings.linkRequestsSubtitle,
      icon: Icons.mark_email_unread,
      iconSemanticLabel: ItStrings.linkRequestsIconLabel,
      onTap: () => context.push(Routes.linkRequests),
      badgeCount: count,
    );
  }
}
