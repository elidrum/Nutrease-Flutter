import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/usecase/get_linked_specialist_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/home/patient_home_view_model.dart';

class _MockGetLinked extends Mock implements GetLinkedSpecialistUseCase {}

const _specialist = Specialist(
  taxCode: 'SPC1',
  firstName: 'Mario',
  surname: 'Rossi',
  email: 'm@e.it',
  vatNumber: '12345678901',
);

void main() {
  late _MockGetLinked getLinked;

  setUp(() => getLinked = _MockGetLinked());

  test('refresh populates the linked specialist and marks loaded', () async {
    when(() => getLinked()).thenAnswer((_) async => const Ok(_specialist));
    final vm = PatientHomeViewModel(getLinked);

    await vm.refresh();

    expect(vm.state.linkedSpecialist, _specialist);
    expect(vm.state.isLinkedSpecialistLoaded, isTrue);
  });

  test('refresh with no link marks loaded with a null specialist', () async {
    when(() => getLinked())
        .thenAnswer((_) async => const Ok<Specialist?>(null));
    final vm = PatientHomeViewModel(getLinked);

    await vm.refresh();

    expect(vm.state.linkedSpecialist, isNull);
    expect(vm.state.isLinkedSpecialistLoaded, isTrue);
  });

  test('a transient error leaves the state not loaded (no false empty state)',
      () async {
    when(() => getLinked()).thenAnswer((_) async => const Err(NetworkError()));
    final vm = PatientHomeViewModel(getLinked);

    await vm.refresh();

    expect(vm.state.isLinkedSpecialistLoaded, isFalse);
    expect(vm.state.linkedSpecialist, isNull);
  });
}
