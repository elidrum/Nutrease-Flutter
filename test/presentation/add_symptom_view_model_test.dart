import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';
import 'package:nutrease_flutter/domain/repository/patient_clinical_file_repository.dart';
import 'package:nutrease_flutter/domain/repository/symptom_repository.dart';
import 'package:nutrease_flutter/domain/usecase/add_symptom_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_fascicolo_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_symptom_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/update_symptom_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/diary/add_symptom_view_model.dart';

class _MockSymptomRepository extends Mock implements SymptomRepository {}

class _MockClinicalFileRepository extends Mock
    implements PatientClinicalFileRepository {}

void main() {
  late _MockSymptomRepository symptomRepo;
  late _MockClinicalFileRepository fileRepo;

  setUpAll(() {
    registerFallbackValue(Symptom(
      fascicoloId: 0,
      date: DateTime(2026),
      time: '00:00:00',
      type: SymptomType.bloating,
      severity: SymptomSeverity.mild,
    ));
  });

  setUp(() {
    symptomRepo = _MockSymptomRepository();
    fileRepo = _MockClinicalFileRepository();
  });

  AddSymptomViewModel buildViewModel({int? symptomId}) => AddSymptomViewModel(
        addSymptomUseCase: AddSymptomUseCase(symptomRepo),
        updateSymptomUseCase: UpdateSymptomUseCase(symptomRepo),
        getSymptomUseCase: GetSymptomUseCase(symptomRepo),
        getPatientFascicoloUseCase: GetPatientFascicoloUseCase(fileRepo),
        symptomId: symptomId,
      );

  test('defaults to bloating + mild in insert mode', () {
    final vm = buildViewModel();
    expect(vm.state.isEditing, isFalse);
    expect(vm.state.type, SymptomType.bloating);
    expect(vm.state.severity, SymptomSeverity.mild);
  });

  group('submit (ADR-0013: insert vs edit)', () {
    test('without symptom_id resolves the fascicolo and inserts', () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => symptomRepo.addSymptom(any()))
          .thenAnswer((_) async => const Ok(7));

      final vm = buildViewModel();
      vm.setType(SymptomType.nausea);
      vm.setSeverity(SymptomSeverity.severe);
      await vm.submit();

      final captured = verify(() => symptomRepo.addSymptom(captureAny()))
          .captured
          .single as Symptom;
      expect(captured.id, isNull);
      expect(captured.fascicoloId, 3);
      expect(captured.type, SymptomType.nausea);
      expect(captured.severity, SymptomSeverity.severe);
      verifyNever(() => symptomRepo.updateSymptom(any()));
      expect(vm.state.saved, isTrue);
    });

    test('with symptom_id prefills via getSymptom and updates', () async {
      final existing = Symptom(
        id: 5,
        fascicoloId: 3,
        date: DateTime(2026, 6, 10),
        time: '14:30:00',
        type: SymptomType.reflux,
        severity: SymptomSeverity.moderate,
      );
      when(() => symptomRepo.getSymptom(5))
          .thenAnswer((_) async => Ok(existing));
      when(() => symptomRepo.updateSymptom(any()))
          .thenAnswer((_) async => const Ok(null));

      final vm = buildViewModel(symptomId: 5);
      await vm.init();
      expect(vm.state.isEditing, isTrue);
      expect(vm.state.type, SymptomType.reflux);
      expect(vm.state.severity, SymptomSeverity.moderate);

      await vm.submit();

      final captured = verify(() => symptomRepo.updateSymptom(captureAny()))
          .captured
          .single as Symptom;
      expect(captured.id, 5);
      expect(captured.fascicoloId, 3);
      verifyNever(() => symptomRepo.addSymptom(any()));
      // The fascicolo comes from the loaded symptom, not from a new lookup.
      verifyNever(() => fileRepo.getActiveFascicoloId());
      expect(vm.state.saved, isTrue);
    });

    test('is single-flight: a double submit performs one insert', () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => symptomRepo.addSymptom(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Ok(7);
      });

      final vm = buildViewModel();
      final first = vm.submit();
      final second = vm.submit();
      await Future.wait([first, second]);

      verify(() => symptomRepo.addSymptom(any())).called(1);
    });

    test('a missing active fascicolo blocks the save with its message',
        () async {
      when(() => fileRepo.getActiveFascicoloId()).thenAnswer(
          (_) async => const Err(NotFoundError('Nessun fascicolo attivo')));

      final vm = buildViewModel();
      await vm.submit();

      expect(vm.state.error, 'Nessun fascicolo attivo');
      verifyNever(() => symptomRepo.addSymptom(any()));
    });
  });

  group('client-side validation (RF10)', () {
    test('a future date blocks the save before any lookup', () async {
      final vm = buildViewModel();
      vm.setDate(DateTime.now().add(const Duration(days: 2)));
      await vm.submit();

      expect(vm.state.error, isNotNull);
      verifyNever(() => fileRepo.getActiveFascicoloId());
      verifyNever(() => symptomRepo.addSymptom(any()));
    });

    test('"Altro" without a free-text label blocks the save', () async {
      final vm = buildViewModel();
      vm.setType(SymptomType.other);
      await vm.submit();

      expect(vm.state.error, isNotNull);
      verifyNever(() => symptomRepo.addSymptom(any()));
    });

    test('"Altro" with free text inserts it as otherDescription', () async {
      when(() => fileRepo.getActiveFascicoloId())
          .thenAnswer((_) async => const Ok(3));
      when(() => symptomRepo.addSymptom(any()))
          .thenAnswer((_) async => const Ok(7));

      final vm = buildViewModel();
      vm.setType(SymptomType.other);
      vm.setOtherDescription('  Mal di testa  ');
      await vm.submit();

      final captured = verify(() => symptomRepo.addSymptom(captureAny()))
          .captured
          .single as Symptom;
      expect(captured.type, SymptomType.other);
      expect(captured.otherDescription, 'Mal di testa'); // trimmed
      expect(vm.state.saved, isTrue);
    });
  });
}
