import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/link_request.dart';
import 'package:nutrease_flutter/domain/model/link_request_status.dart';
import 'package:nutrease_flutter/domain/model/link_request_with_patient.dart';
import 'package:nutrease_flutter/domain/usecase/accept_link_request_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_received_link_requests_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/reject_link_request_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/requests/link_requests_view_model.dart';

class _MockGetReceived extends Mock
    implements GetReceivedLinkRequestsUseCase {}

class _MockAccept extends Mock implements AcceptLinkRequestUseCase {}

class _MockReject extends Mock implements RejectLinkRequestUseCase {}

LinkRequestWithPatient _item(int id) => LinkRequestWithPatient(
      request: LinkRequest(
        id: id,
        patientTaxCode: 'PAT$id',
        specialistTaxCode: 'SPC1',
        status: LinkRequestStatus.sent,
        createdAt: DateTime(2026, 6, 13),
      ),
      patientFirstName: 'Mario',
      patientSurname: 'Rossi',
    );

void main() {
  late _MockGetReceived getReceived;
  late _MockAccept accept;
  late _MockReject reject;

  setUp(() {
    getReceived = _MockGetReceived();
    accept = _MockAccept();
    reject = _MockReject();
  });

  LinkRequestsViewModel buildViewModel() => LinkRequestsViewModel(
        getReceived: getReceived,
        accept: accept,
        reject: reject,
      );

  group('load', () {
    test('success exposes the list and the pending count', () async {
      when(() => getReceived())
          .thenAnswer((_) async => Ok([_item(1), _item(2)]));

      final vm = buildViewModel();
      await vm.load();

      expect(vm.state.requests, isA<Success<List<LinkRequestWithPatient>>>());
      expect(vm.pendingCount, 2);
    });

    test('empty result yields a pending count of zero', () async {
      when(() => getReceived())
          .thenAnswer((_) async => const Ok(<LinkRequestWithPatient>[]));

      final vm = buildViewModel();
      await vm.load();

      expect(vm.pendingCount, 0);
    });

    test('failure surfaces as a Failure resource', () async {
      when(() => getReceived())
          .thenAnswer((_) async => const Err(NetworkError()));

      final vm = buildViewModel();
      await vm.load();

      expect(vm.state.requests, isA<Failure<List<LinkRequestWithPatient>>>());
    });
  });

  group('accept (RF16)', () {
    test('removes the accepted request from the list', () async {
      when(() => getReceived())
          .thenAnswer((_) async => Ok([_item(1), _item(2)]));
      when(() => accept(1)).thenAnswer((_) async => const Ok(null));

      final vm = buildViewModel();
      await vm.load();
      final ok = await vm.accept(1);

      expect(ok, isTrue);
      expect(vm.pendingCount, 1);
      verify(() => accept(1)).called(1);
    });
  });

  group('reject (RF17)', () {
    test('a blocked reject (use case error) keeps the request', () async {
      when(() => getReceived()).thenAnswer((_) async => Ok([_item(1)]));
      when(() => reject(1, '')).thenAnswer(
          (_) async => const Err(ValidationError('La motivazione è obbligatoria.')));

      final vm = buildViewModel();
      await vm.load();
      final ok = await vm.reject(1, '');

      expect(ok, isFalse);
      expect(vm.pendingCount, 1);
    });

    test('with a reason calls the use case and removes the request', () async {
      when(() => getReceived()).thenAnswer((_) async => Ok([_item(1)]));
      when(() => reject(1, 'Agenda piena'))
          .thenAnswer((_) async => const Ok(null));

      final vm = buildViewModel();
      await vm.load();
      final ok = await vm.reject(1, 'Agenda piena');

      expect(ok, isTrue);
      expect(vm.pendingCount, 0);
      verify(() => reject(1, 'Agenda piena')).called(1);
    });
  });

  group('single-flight', () {
    test('a double accept performs one use-case call', () async {
      when(() => getReceived()).thenAnswer((_) async => Ok([_item(1)]));
      when(() => accept(1)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return const Ok(null);
      });

      final vm = buildViewModel();
      await vm.load();
      final first = vm.accept(1);
      final second = vm.accept(1);
      await Future.wait([first, second]);

      verify(() => accept(1)).called(1);
    });
  });
}
