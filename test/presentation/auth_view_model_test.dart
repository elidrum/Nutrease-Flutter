import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/usecase/login_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/send_password_reset_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/auth/auth_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;
  late AuthViewModel vm;

  setUp(() {
    auth = _MockAuthRepository();
    vm = AuthViewModel(LoginUseCase(auth), SendPasswordResetUseCase(auth));
  });

  test('starts idle', () {
    expect(vm.state.isLoading, isFalse);
    expect(vm.state.navigateTo, isNull);
    expect(vm.state.error, isNull);
  });

  test('login success sets navigateTo to the resolved role', () async {
    when(() => auth.login(any(), any())).thenAnswer(
      (_) async => const Ok(AuthUser(
        userId: 'u',
        email: 'a@b.com',
        role: UserRole.specialist,
        taxCode: 'CF',
      )),
    );

    await vm.login('a@b.com', 'Password1');

    expect(vm.state.isLoading, isFalse);
    expect(vm.state.navigateTo, UserRole.specialist);
    expect(vm.state.error, isNull);
  });

  test('login failure sets a generic error and does not navigate', () async {
    when(() => auth.login(any(), any()))
        .thenAnswer((_) async => const Err(AuthError()));

    await vm.login('a@b.com', 'wrong');

    expect(vm.state.navigateTo, isNull);
    expect(vm.state.error, 'Credenziali non valide.');
  });

  test('login is single-flight: a second call while loading is a no-op',
      () async {
    final gate = Completer<void>();
    when(() => auth.login(any(), any())).thenAnswer((_) async {
      await gate.future;
      return const Ok(AuthUser(
        userId: 'u',
        email: 'a@b.com',
        role: UserRole.patient,
        taxCode: 'CF',
      ));
    });

    final first = vm.login('a@b.com', 'Password1');
    expect(vm.state.isLoading, isTrue);
    await vm.login('a@b.com', 'Password1'); // ignored while in flight
    gate.complete();
    await first;

    verify(() => auth.login(any(), any())).called(1);
  });

  group('sendPasswordReset', () {
    test('a valid email sends the reset and flags passwordResetSent', () async {
      when(() => auth.sendPasswordReset(any()))
          .thenAnswer((_) async => const Ok(null));

      await vm.sendPasswordReset('user@example.com');

      expect(vm.state.passwordResetSent, isTrue);
      expect(vm.state.error, isNull);
      verify(() => auth.sendPasswordReset('user@example.com')).called(1);
    });

    test('an email without @ fails validation and never hits the repository',
        () async {
      await vm.sendPasswordReset('not-an-email');

      expect(vm.state.passwordResetSent, isFalse);
      expect(vm.state.error, isNotNull);
      verifyNever(() => auth.sendPasswordReset(any()));
    });

    test('is single-flight: a second call while sending is a no-op', () async {
      final gate = Completer<void>();
      when(() => auth.sendPasswordReset(any())).thenAnswer((_) async {
        await gate.future;
        return const Ok(null);
      });

      final first = vm.sendPasswordReset('user@example.com');
      expect(vm.state.isSendingReset, isTrue);
      await vm.sendPasswordReset('user@example.com'); // ignored while in flight
      gate.complete();
      await first;

      verify(() => auth.sendPasswordReset(any())).called(1);
    });
  });
}
