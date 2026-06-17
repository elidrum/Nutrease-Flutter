import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/repository/user_repository.dart';
import 'package:nutrease_flutter/domain/usecase/change_password_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/delete_account_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_profile_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/logout_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/update_patient_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/update_specialist_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/profile/profile_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockAuthRepository auth;
  late _MockUserRepository user;

  const authUser = AuthUser(
    userId: 'u',
    email: 'a@b.com',
    role: UserRole.patient,
    taxCode: 'CF',
  );

  ProfileViewModel buildViewModel() => ProfileViewModel(
        GetProfileUseCase(user),
        UpdatePatientUseCase(user),
        UpdateSpecialistUseCase(user),
        ChangePasswordUseCase(auth),
        DeleteAccountUseCase(auth),
        LogoutUseCase(auth),
      );

  setUp(() {
    auth = _MockAuthRepository();
    user = _MockUserRepository();
  });

  test('changePassword re-authenticates before updating the password',
      () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => authUser);
    when(() => auth.reauthenticate(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.changePassword(any()))
        .thenAnswer((_) async => const Ok(null));

    final vm = buildViewModel();
    await vm.changePassword('OldPass1', 'NewPass1');

    verify(() => auth.reauthenticate('a@b.com', 'OldPass1')).called(1);
    verify(() => auth.changePassword('NewPass1')).called(1);
    expect(vm.state.successMessage, isNotNull);
    expect(vm.state.error, isNull);
  });

  test('deleteAccount re-authenticates, deletes, then logs out', () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => authUser);
    when(() => auth.reauthenticate(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => auth.deleteAccount()).thenAnswer((_) async => const Ok(null));
    when(() => auth.logout()).thenAnswer((_) async => const Ok(null));

    final vm = buildViewModel();
    await vm.deleteAccount('MyPass1');

    verify(() => auth.reauthenticate('a@b.com', 'MyPass1')).called(1);
    verify(() => auth.deleteAccount()).called(1);
    verify(() => auth.logout()).called(1);
    expect(vm.state.navigateToLogin, isTrue);
  });

  test('a wrong password aborts deletion (no delete, no logout)', () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => authUser);
    when(() => auth.reauthenticate(any(), any()))
        .thenAnswer((_) async => const Err(AuthError()));

    final vm = buildViewModel();
    await vm.deleteAccount('wrong');

    verifyNever(() => auth.deleteAccount());
    verifyNever(() => auth.logout());
    expect(vm.state.navigateToLogin, isFalse);
    expect(vm.state.error, isNotNull);
  });

  test('logout navigates to login', () async {
    when(() => auth.logout()).thenAnswer((_) async => const Ok(null));

    final vm = buildViewModel();
    await vm.logout();

    expect(vm.state.navigateToLogin, isTrue);
  });
}
