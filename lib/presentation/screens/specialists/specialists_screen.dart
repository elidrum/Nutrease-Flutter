import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../domain/model/specialist.dart';
import '../../../domain/model/specialization_type.dart';
import '../../../domain/usecase/get_excluded_specialist_tax_codes_use_case.dart';
import '../../../domain/usecase/get_linked_specialist_use_case.dart';
import '../../../domain/usecase/search_specialists_use_case.dart';
import '../../../domain/usecase/send_link_request_use_case.dart';
import 'specialists_view_model.dart';

/// Discovery degli specialisti (RF13/RF14): tre filtri combinabili (testo + città
/// in debounce, dropdown specializzazione immediato), una lista paginata a
/// infinite-scroll e un dialog di invio richiesta. Mostra un avviso di sostituzione
/// quando il paziente è già collegato.
class SpecialistsScreen extends StatelessWidget {
  const SpecialistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpecialistsViewModel>(
      create: (ctx) => SpecialistsViewModel(
        searchSpecialists: ctx.read<SearchSpecialistsUseCase>(),
        sendLinkRequest: ctx.read<SendLinkRequestUseCase>(),
        getExcluded: ctx.read<GetExcludedSpecialistTaxCodesUseCase>(),
        getLinkedSpecialist: ctx.read<GetLinkedSpecialistUseCase>(),
      )..init(),
      child: const _SpecialistsView(),
    );
  }
}

class _SpecialistsView extends StatelessWidget {
  const _SpecialistsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpecialistsViewModel>();
    final state = vm.state;

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.specialistsTitle)),
      body: Column(
        children: [
          _FilterBar(state: state, vm: vm),
          if (state.linkedSpecialistName != null)
            _ReplacementBanner(name: state.linkedSpecialistName!),
          Expanded(child: _ResultsList(state: state, vm: vm)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final SpecialistsUiState state;
  final SpecialistsViewModel vm;

  const _FilterBar({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, semanticLabel: ItStrings.searchIconLabel),
              hintText: ItStrings.specialistSearchHint,
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onChanged: vm.setText,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<SpecializationType?>(
                  initialValue: state.specialization,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: ItStrings.specializationFilter,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<SpecializationType?>(
                      value: null,
                      child: Text(ItStrings.specializationAll),
                    ),
                    for (final s in SpecializationType.values)
                      DropdownMenuItem<SpecializationType?>(
                        value: s,
                        child: Text(s.dbLabel),
                      ),
                  ],
                  onChanged: vm.setSpecialization,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: ItStrings.cityFilter,
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: vm.setCity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner mostrato quando il paziente è già collegato (delta RF13/RF14).
class _ReplacementBanner extends StatelessWidget {
  final String name;

  const _ReplacementBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: scheme.onTertiaryContainer,
              semanticLabel: ItStrings.warningIconLabel),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Text(
              ItStrings.specialistsAlreadyLinkedWarning(name),
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final SpecialistsUiState state;
  final SpecialistsViewModel vm;

  const _ResultsList({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(message: state.error!, onRetry: vm.retry);
    }
    if (state.isEmpty) {
      return const EmptyView(message: ItStrings.specialistsEmpty);
    }

    final showBottomLoader = state.isLoadingPage && state.items.isNotEmpty;
    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      itemCount: state.items.length + (showBottomLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppTokens.spacingMd),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Infinite-scroll: prefetch della pagina successiva 3 item prima della fine.
        if (index >= state.items.length - 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) => vm.loadNextPage());
        }
        return _SpecialistCard(
          specialist: state.items[index],
          onRequest: () => _openSendDialog(context, vm, state.items[index]),
        );
      },
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final Specialist specialist;
  final VoidCallback onRequest;

  const _SpecialistCard({required this.specialist, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (specialist.specialization != null) specialist.specialization!.dbLabel,
      if (specialist.city != null && specialist.city!.isNotEmpty)
        specialist.city!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services,
                    color: scheme.primary,
                    semanticLabel: ItStrings.specialistIconLabel),
                const SizedBox(width: AppTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${specialist.firstName} ${specialist.surname}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spacingXs),
                        Text(
                          subtitle,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.link),
                label: const Text(ItStrings.requestLinkAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apre il dialog di invio richiesta (messaggio opzionale, max 500). Ripete
/// l'avviso di sostituzione quando il paziente è già collegato, ritentando prima
/// la fetch dello specialista collegato se era fallita.
Future<void> _openSendDialog(
  BuildContext context,
  SpecialistsViewModel vm,
  Specialist specialist,
) async {
  // Retry best-effort così l'avviso non si perde dopo un errore transitorio.
  await vm.ensureLinkedSpecialistLoaded();
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => ChangeNotifierProvider<SpecialistsViewModel>.value(
      value: vm,
      child: _SendRequestDialog(specialist: specialist),
    ),
  );
  if (sent == true) {
    messenger.showSnackBar(
      const SnackBar(content: Text(ItStrings.linkRequestSent)),
    );
  } else if (sent == false) {
    messenger.showSnackBar(
      const SnackBar(content: Text(ItStrings.linkRequestActionError)),
    );
  }
}

class _SendRequestDialog extends StatefulWidget {
  final Specialist specialist;

  const _SendRequestDialog({required this.specialist});

  @override
  State<_SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<_SendRequestDialog> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final text = _message.text.trim();
    final ok = await context.read<SpecialistsViewModel>().sendRequest(
          widget.specialist.taxCode,
          message: text.isEmpty ? null : text,
        );
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final linkedName =
        context.watch<SpecialistsViewModel>().state.linkedSpecialistName;
    return AlertDialog(
      title: const Text(ItStrings.sendLinkRequestTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.specialist.firstName} ${widget.specialist.surname}'),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: _message,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: ItStrings.linkRequestMessageHint,
              border: OutlineInputBorder(),
            ),
          ),
          if (linkedName != null) ...[
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              ItStrings.sendLinkRequestReplaceWarning(linkedName),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text(ItStrings.cancel),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: const Text(ItStrings.sendAction),
        ),
      ],
    );
  }
}
