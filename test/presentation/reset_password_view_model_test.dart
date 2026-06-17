import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/usecase/reset_password_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/auth/reset_password_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;

  ResetPasswordViewModel buildViewModel() =>
      ResetPasswordViewModel(ResetPasswordUseCase(auth), email: 'a@b.com');

  setUp(() => auth = _MockAuthRepository());

  test('mismatched passwords set an error and never hit the repository',
      () async {
    final vm = buildViewModel();

    await vm.submit(
      code: '12345678',
      newPassword: 'Password1',
      confirmPassword: 'Password2',
    );

    expect(vm.state.error, isNotNull);
    expect(vm.state.done, isFalse);
    verifyNever(() => auth.verifyRecoveryOtp(any(), any()));
  });

  test('a successful reset flags done', () async {
    when(() => auth.verifyRecoveryOtp(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.changePassword(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.logout()).thenAnswer((_) async => const Ok(null));

    final vm = buildViewModel();
    await vm.submit(
      code: '12345678',
      newPassword: 'Password1',
      confirmPassword: 'Password1',
    );

    expect(vm.state.done, isTrue);
    expect(vm.state.error, isNull);
  });
}
