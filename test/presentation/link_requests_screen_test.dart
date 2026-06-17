import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/core/strings/it_strings.dart';
import 'package:nutrease_flutter/core/theme/app_theme.dart';
import 'package:nutrease_flutter/domain/model/link_request.dart';
import 'package:nutrease_flutter/domain/model/link_request_status.dart';
import 'package:nutrease_flutter/domain/model/link_request_with_patient.dart';
import 'package:nutrease_flutter/domain/usecase/accept_link_request_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_received_link_requests_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/reject_link_request_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/requests/link_requests_screen.dart';
import 'package:provider/provider.dart';

class _MockGetReceived extends Mock implements GetReceivedLinkRequestsUseCase {}

class _MockAccept extends Mock implements AcceptLinkRequestUseCase {}

class _MockReject extends Mock implements RejectLinkRequestUseCase {}

LinkRequestWithPatient _item(int id) => LinkRequestWithPatient(
      request: LinkRequest(
        id: id,
        patientTaxCode: 'PAT$id',
        specialistTaxCode: 'SPC1',
        status: LinkRequestStatus.sent,
        message: 'Buongiorno dottore',
        createdAt: DateTime(2026, 6, 13, 10, 30),
      ),
      patientFirstName: 'Mario',
      patientSurname: 'Rossi',
    );

void main() {
  setUpAll(() async => initializeDateFormatting('it_IT'));

  testWidgets('renders a real request card without throwing', (tester) async {
    final getReceived = _MockGetReceived();
    when(() => getReceived()).thenAnswer((_) async => Ok([_item(1)]));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GetReceivedLinkRequestsUseCase>.value(value: getReceived),
          Provider<AcceptLinkRequestUseCase>.value(value: _MockAccept()),
          Provider<RejectLinkRequestUseCase>.value(value: _MockReject()),
        ],
        // Tema REALE dell'app: riproduce l'overflow del FilledButton in Row.
        child: MaterialApp(theme: AppTheme.light, home: const LinkRequestsScreen()),
      ),
    );
    await tester.pump(); // resolve getReceived() → Success

    expect(tester.takeException(), isNull,
        reason: 'la card non deve andare in overflow col tema reale');
    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text(ItStrings.acceptAction), findsOneWidget);
    expect(find.text(ItStrings.rejectAction), findsOneWidget);
  });
}
