import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/gender.dart';
import 'package:nutrease_flutter/domain/model/register_data.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/usecase/register_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/auth/register_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      PatientRegisterData(
        email: '',
        password: '',
        firstName: '',
        surname: '',
        taxCode: '',
        gender: Gender.male,
        birthDate: DateTime(2000),
      ),
    );
  });

  late _MockAuthRepository auth;
  late RegisterViewModel vm;

  setUp(() {
    auth = _MockAuthRepository();
    vm = RegisterViewModel(RegisterUseCase(auth));
  });

  test('a weak password blocks submit and never calls the repository',
      () async {
    await vm.submitPatient(
      email: 'mario@example.com',
      password: 'weak',
      firstName: 'Mario',
      surname: 'Rossi',
      taxCode: 'RSSMRA80A01H501U',
      gender: Gender.male,
      birthDateText: '01/01/2000',
    );

    expect(vm.state.fieldErrors[RegisterField.password], isNotNull);
    expect(vm.state.navigateTo, isNull);
    verifyNever(() => auth.register(any()));
  });

  test('an age under 18 blocks submit', () async {
    await vm.submitPatient(
      email: 'mario@example.com',
      password: 'Password1',
      firstName: 'Mario',
      surname: 'Rossi',
      taxCode: 'RSSMRA80A01H501U',
      gender: Gender.male,
      // ~16 years old at the project date: rejected at 18 (would pass at 13).
      birthDateText: '01/01/2010',
    );

    expect(vm.state.fieldErrors[RegisterField.birthDate], isNotNull);
    verifyNever(() => auth.register(any()));
  });

  test('a valid patient submit navigates to the patient home', () async {
    when(() => auth.register(any())).thenAnswer((_) async => const Ok(null));

    await vm.submitPatient(
      email: 'mario@example.com',
      password: 'Password1',
      firstName: 'Mario',
      surname: 'Rossi',
      taxCode: 'RSSMRA80A01H501U',
      gender: Gender.male,
      birthDateText: '01/01/2000',
    );

    expect(vm.state.fieldErrors, isEmpty);
    expect(vm.state.navigateTo, UserRole.patient);
    verify(() => auth.register(any())).called(1);
  });
}
