import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/repository/link_request_repository.dart';
import 'package:nutrease_flutter/domain/usecase/accept_link_request_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/reject_link_request_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/send_link_request_use_case.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockLinkRequestRepo extends Mock implements LinkRequestRepository {}

const _patient = AuthUser(
  userId: 'u1',
  email: 'p@e.it',
  role: UserRole.patient,
  taxCode: 'PAT1',
);

const _specialist = AuthUser(
  userId: 'u2',
  email: 's@e.it',
  role: UserRole.specialist,
  taxCode: 'SPC1',
);

void main() {
  late _MockAuth auth;
  late _MockLinkRequestRepo repo;

  setUp(() {
    auth = _MockAuth();
    repo = _MockLinkRequestRepo();
  });

  group('SendLinkRequestUseCase (RF14)', () {
    test('patient: forwards to the repository', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _patient);
      when(() => repo.sendLinkRequest(any(), message: any(named: 'message')))
          .thenAnswer((_) async => const Ok(null));

      final result = await SendLinkRequestUseCase(auth, repo)('SPC1', message: 'x');

      expect(result, isA<Ok<void>>());
      verify(() => repo.sendLinkRequest('SPC1', message: 'x')).called(1);
    });

    test('specialist: guarded, repository untouched', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _specialist);

      final result = await SendLinkRequestUseCase(auth, repo)('SPC1');

      expect((result as Err<void>).error, isA<ValidationError>());
      verifyNever(
          () => repo.sendLinkRequest(any(), message: any(named: 'message')));
    });
  });

  group('AcceptLinkRequestUseCase (RF16)', () {
    test('specialist: forwards to the repository', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _specialist);
      when(() => repo.acceptLinkRequest(any()))
          .thenAnswer((_) async => const Ok(null));

      final result = await AcceptLinkRequestUseCase(auth, repo)(5);

      expect(result, isA<Ok<void>>());
      verify(() => repo.acceptLinkRequest(5)).called(1);
    });

    test('patient: guarded, repository untouched', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _patient);

      final result = await AcceptLinkRequestUseCase(auth, repo)(5);

      expect((result as Err<void>).error, isA<ValidationError>());
      verifyNever(() => repo.acceptLinkRequest(any()));
    });
  });

  group('RejectLinkRequestUseCase (RF17)', () {
    test('empty reason is blocked before any role/repo call', () async {
      final result = await RejectLinkRequestUseCase(auth, repo)(5, '   ');

      expect((result as Err<void>).error, isA<ValidationError>());
      verifyNever(() => auth.getCurrentUser());
      verifyNever(() => repo.rejectLinkRequest(any(), any()));
    });

    test('specialist with a reason: forwards the trimmed reason', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _specialist);
      when(() => repo.rejectLinkRequest(any(), any()))
          .thenAnswer((_) async => const Ok(null));

      final result =
          await RejectLinkRequestUseCase(auth, repo)(5, '  Agenda piena  ');

      expect(result, isA<Ok<void>>());
      verify(() => repo.rejectLinkRequest(5, 'Agenda piena')).called(1);
    });

    test('patient with a reason: guarded, repository untouched', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _patient);

      final result = await RejectLinkRequestUseCase(auth, repo)(5, 'reason');

      expect((result as Err<void>).error, isA<ValidationError>());
      verifyNever(() => repo.rejectLinkRequest(any(), any()));
    });
  });
}
