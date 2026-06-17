import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/linked_patient.dart';
import 'package:nutrease_flutter/domain/usecase/get_linked_patients_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/linkedpatients/linked_patients_view_model.dart';

class _MockGetLinkedPatients extends Mock
    implements GetLinkedPatientsUseCase {}

LinkedPatient _patient(String surname) => LinkedPatient(
      fascicoloId: surname.hashCode,
      taxCode: 'CF$surname',
      firstName: 'Mario',
      surname: surname,
    );

void main() {
  late _MockGetLinkedPatients getLinkedPatients;

  setUp(() => getLinkedPatients = _MockGetLinkedPatients());

  LinkedPatientsViewModel build() =>
      LinkedPatientsViewModel(getLinkedPatients: getLinkedPatients);

  test('load resolves to success with the patients', () async {
    when(() => getLinkedPatients())
        .thenAnswer((_) async => Ok([_patient('Rossi')]));

    final vm = build();
    expect(vm.state.patients, isA<Loading<List<LinkedPatient>>>());

    await vm.load();

    final patients = vm.state.patients;
    expect(patients, isA<Success<List<LinkedPatient>>>());
    expect((patients as Success<List<LinkedPatient>>).data, hasLength(1));
  });

  test('load resolves to an empty success', () async {
    when(() => getLinkedPatients())
        .thenAnswer((_) async => const Ok(<LinkedPatient>[]));

    final vm = build();
    await vm.load();

    final patients = vm.state.patients as Success<List<LinkedPatient>>;
    expect(patients.data, isEmpty);
  });

  test('load surfaces a repository failure', () async {
    when(() => getLinkedPatients())
        .thenAnswer((_) async => const Err(NetworkError()));

    final vm = build();
    await vm.load();

    expect(vm.state.patients, isA<Failure<List<LinkedPatient>>>());
  });

  test('refresh keeps the current list visible (no loading flash)', () async {
    when(() => getLinkedPatients())
        .thenAnswer((_) async => Ok([_patient('Rossi')]));

    final vm = build();
    await vm.load();
    expect(vm.state.patients, isA<Success<List<LinkedPatient>>>());

    // Second load is in-flight: state must stay Success, not flip to Loading.
    final pending = Completer<Result<List<LinkedPatient>>>();
    when(() => getLinkedPatients()).thenAnswer((_) => pending.future);

    final future = vm.load();
    expect(vm.state.patients, isA<Success<List<LinkedPatient>>>());

    pending.complete(Ok([_patient('Bianchi'), _patient('Rossi')]));
    await future;
    expect((vm.state.patients as Success<List<LinkedPatient>>).data,
        hasLength(2));
  });
}
