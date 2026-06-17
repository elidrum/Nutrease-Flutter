import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/usecase/reset_password_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;
  late ResetPasswordUseCase useCase;

  setUp(() {
    auth = _MockAuthRepository();
    useCase = ResetPasswordUseCase(auth);
  });

  test('rejects a code that is not 8 digits, without calling the repository',
      () async {
    final result =
        await useCase(email: 'a@b.com', code: '123', newPassword: 'Password1');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).error, isA<ValidationError>());
    verifyNever(() => auth.verifyRecoveryOtp(any(), any()));
  });

  test('rejects a weak password before verifying the code', () async {
    final result =
        await useCase(email: 'a@b.com', code: '12345678', newPassword: 'weak');

    expect((result as Err<void>).error, isA<ValidationError>());
    verifyNever(() => auth.verifyRecoveryOtp(any(), any()));
  });

  test('verifies the code, changes the password and signs out on success',
      () async {
    when(() => auth.verifyRecoveryOtp(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.changePassword(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.logout()).thenAnswer((_) async => const Ok(null));

    final result = await useCase(
      email: 'a@b.com',
      code: '12345678',
      newPassword: 'Password1',
    );

    expect(result, isA<Ok<void>>());
    verify(() => auth.verifyRecoveryOtp('a@b.com', '12345678')).called(1);
    verify(() => auth.changePassword('Password1')).called(1);
    verify(() => auth.logout()).called(1);
  });

  test('a wrong code aborts before changing the password', () async {
    when(() => auth.verifyRecoveryOtp(any(), any())).thenAnswer(
      (_) async => const Err(ValidationError('Codice non valido o scaduto.')),
    );

    final result = await useCase(
      email: 'a@b.com',
      code: '12345678',
      newPassword: 'Password1',
    );

    expect(result, isA<Err<void>>());
    verifyNever(() => auth.changePassword(any()));
    verifyNever(() => auth.logout());
  });
}
