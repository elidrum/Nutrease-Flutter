import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/repository/specialist_directory_repository.dart';
import 'package:nutrease_flutter/domain/usecase/get_linked_specialist_use_case.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockDirectory extends Mock implements SpecialistDirectoryRepository {}

const _specialist = Specialist(
  taxCode: 'SPC1',
  firstName: 'Mario',
  surname: 'Rossi',
  email: 'm@e.it',
  vatNumber: '12345678901',
);

const _patient = AuthUser(
  userId: 'u1',
  email: 'p@e.it',
  role: UserRole.patient,
  taxCode: 'PAT1',
);

const _specialistUser = AuthUser(
  userId: 'u2',
  email: 's@e.it',
  role: UserRole.specialist,
  taxCode: 'SPC1',
);

void main() {
  late _MockAuth auth;
  late _MockDirectory directory;
  late GetLinkedSpecialistUseCase useCase;

  setUp(() {
    auth = _MockAuth();
    directory = _MockDirectory();
    useCase = GetLinkedSpecialistUseCase(auth, directory);
  });

  test('patient: resolves the linked specialist by tax code', () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => _patient);
    when(() => directory.getLinkedSpecialist('PAT1'))
        .thenAnswer((_) async => const Ok(_specialist));

    final result = await useCase();

    expect(result, isA<Ok<Specialist?>>());
    expect((result as Ok<Specialist?>).value, _specialist);
    verify(() => directory.getLinkedSpecialist('PAT1')).called(1);
  });

  test('patient with no active file: returns Ok(null)', () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => _patient);
    when(() => directory.getLinkedSpecialist('PAT1'))
        .thenAnswer((_) async => const Ok(null));

    final result = await useCase();
    expect((result as Ok<Specialist?>).value, isNull);
  });

  test('specialist logged in: guarded with a ValidationError, no repo call',
      () async {
    when(() => auth.getCurrentUser())
        .thenAnswer((_) async => _specialistUser);

    final result = await useCase();

    expect(result, isA<Err<Specialist?>>());
    expect((result as Err<Specialist?>).error, isA<ValidationError>());
    verifyNever(() => directory.getLinkedSpecialist(any()));
  });

  test('signed out: guarded with an error, no repo call', () async {
    when(() => auth.getCurrentUser()).thenAnswer((_) async => null);

    final result = await useCase();
    expect(result, isA<Err<Specialist?>>());
    verifyNever(() => directory.getLinkedSpecialist(any()));
  });
}
