import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/error/result.dart';
import '../../../core/strings/it_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../domain/model/linked_patient.dart';
import '../../../domain/usecase/get_linked_patients_use_case.dart';
import '../../navigation/routes.dart';
import 'linked_patients_view_model.dart';

/// Lista pazienti collegati dello specialista (RF18): pazienti con un fascicolo
/// clinico attivo, ordinati per cognome, tap per aprire il loro diario read-only
/// (RF19).
class LinkedPatientsScreen extends StatelessWidget {
  const LinkedPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LinkedPatientsViewModel>(
      create: (ctx) => LinkedPatientsViewModel(
        getLinkedPatients: ctx.read<GetLinkedPatientsUseCase>(),
      )..load(),
      child: const _LinkedPatientsView(),
    );
  }
}

class _LinkedPatientsView extends StatelessWidget {
  const _LinkedPatientsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LinkedPatientsViewModel>();
    final patients = vm.state.patients;

    return Scaffold(
      appBar: AppBar(title: const Text(ItStrings.linkedPatientsTitle)),
      body: switch (patients) {
        Loading<List<LinkedPatient>>() => const LoadingView(),
        Failure<List<LinkedPatient>>(:final error) => RefreshIndicator(
            onRefresh: vm.load,
            child: _ScrollableFill(
              child: ErrorView(message: error.message, onRetry: vm.load),
            ),
          ),
        Success<List<LinkedPatient>>(:final data) => RefreshIndicator(
            onRefresh: vm.load,
            child: data.isEmpty
                ? const _ScrollableFill(
                    child: EmptyView(message: ItStrings.linkedPatientsEmpty),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _PatientCard(patient: data[index]),
                  ),
          ),
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final LinkedPatient patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final age = patient.ageAt(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.person, semanticLabel: null),
        ),
        title: Text(
          patient.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: age == null
            ? null
            : Text(
                ItStrings.patientAgeYears(age),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: const Icon(Icons.chevron_right, semanticLabel: null),
        onTap: () => context.push(_patientDiaryRoute(patient)),
      ),
    );
  }

  String _patientDiaryRoute(LinkedPatient patient) => Uri(
        path: Routes.patientDiary,
        queryParameters: {
          'fascicolo_id': '${patient.fascicoloId}',
          'patient_name': patient.fullName,
        },
      ).toString();
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
