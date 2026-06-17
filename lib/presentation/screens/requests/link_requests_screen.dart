import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../domain/model/link_request_with_patient.dart';
import '../../../domain/usecase/accept_link_request_use_case.dart';
import '../../../domain/usecase/get_received_link_requests_use_case.dart';
import '../../../domain/usecase/reject_link_request_use_case.dart';
import 'link_requests_view_model.dart';

/// Inbox dello specialista (RF15–RF17): richieste pendenti dalla più recente, con
/// azioni di accetta e rifiuta-con-motivazione-obbligatoria e pull-to-refresh.
class LinkRequestsScreen extends StatelessWidget {
  const LinkRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LinkRequestsViewModel>(
      create: (ctx) => LinkRequestsViewModel(
        getReceived: ctx.read<GetReceivedLinkRequestsUseCase>(),
        accept: ctx.read<AcceptLinkRequestUseCase>(),
        reject: ctx.read<RejectLinkRequestUseCase>(),
      )..load(),
      child: const _LinkRequestsView(),
    );
  }
}

class _LinkRequestsView extends StatelessWidget {
  const _LinkRequestsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinkRequestsViewModel>();
    final requests = vm.state.requests;

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.linkRequestsTitle)),
      body: switch (requests) {
        Loading<List<LinkRequestWithPatient>>() => const LoadingView(),
        Failure<List<LinkRequestWithPatient>>(:final error) => RefreshIndicator(
            onRefresh: vm.load,
            child: _ScrollableFill(
              child: ErrorView(message: error.message, onRetry: vm.load),
            ),
          ),
        Success<List<LinkRequestWithPatient>>(:final data) => RefreshIndicator(
            onRefresh: vm.load,
            child: data.isEmpty
                ? const _ScrollableFill(
                    child: EmptyView(message: ItStrings.linkRequestsEmpty),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    itemCount: data.length,
                    itemBuilder: (context, index) => _RequestCard(
                      item: data[index],
                      vm: vm,
                    ),
                  ),
          ),
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final LinkRequestWithPatient item;
  final LinkRequestsViewModel vm;

  const _RequestCard({required this.item, required this.vm});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = item.request.message;
    final timestamp = DateFormat('d MMMM yyyy, HH:mm', 'it_IT')
        .format(item.request.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.patientFullName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              timestamp,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              message == null || message.isEmpty
                  ? ItStrings.noMessage
                  : message,
              style: message == null || message.isEmpty
                  ? TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic)
                  : null,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _reject(context),
                  child: const Text(ItStrings.rejectAction),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                FilledButton(
                  onPressed: () => _accept(context),
                  // Il filledButtonTheme globale impone minimumSize Size.fromHeight
                  // (larghezza infinita, pensata per le CTA a tutta larghezza nelle
                  // Column): dentro questa Row manderebbe "Accetta" in overflow oltre
                  // il bordo destro, rendendolo invisibile. Qui lo riporto a
                  // larghezza-contenuto mantenendo l'altezza standard.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppTokens.buttonHeight),
                  ),
                  child: const Text(ItStrings.acceptAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.accept(item.request.id);
    messenger.showSnackBar(SnackBar(
      content: Text(
          ok ? ItStrings.linkRequestAccepted : ItStrings.linkRequestActionError),
    ));
  }

  Future<void> _reject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null) return; // annullato
    final ok = await vm.reject(item.request.id, reason);
    messenger.showSnackBar(SnackBar(
      content: Text(
          ok ? ItStrings.linkRequestRejected : ItStrings.linkRequestActionError),
    ));
  }
}

/// Dialog di rifiuto con motivazione obbligatoria (RF17): conferma disabilitata
/// finché il campo è vuoto. Restituisce la motivazione trimmata, o `null` se annullato.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text(ItStrings.rejectLinkRequestTitle),
      content: TextField(
        controller: _reason,
        maxLength: 500,
        maxLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: ItStrings.rejectReasonHint,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ItStrings.cancel),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: const Text(ItStrings.rejectAction),
        ),
      ],
    );
  }
}

/// Fa riempire la viewport a un messaggio centrato così il `RefreshIndicator` può tirare.
class _ScrollableFill extends StatelessWidget {
  final Widget child;

  const _ScrollableFill({required this.child});

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
