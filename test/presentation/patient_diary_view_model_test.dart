import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/diary_date_range.dart';
import 'package:nutrease_flutter/domain/model/nutrient_filter.dart';
import 'package:nutrease_flutter/domain/model/patient_diary_day.dart';
import 'package:nutrease_flutter/domain/usecase/get_patient_diary_range_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/patientdiary/patient_diary_view_model.dart';

class _MockGetRange extends Mock implements GetPatientDiaryRangeUseCase {}

PatientDiaryDay _day(DateTime date) => PatientDiaryDay(date: date);

void main() {
  late _MockGetRange getRange;

  setUpAll(() => registerFallbackValue(DiaryDateRange.today()));

  setUp(() => getRange = _MockGetRange());

  PatientDiaryViewModel build() => PatientDiaryViewModel(
        fascicoloId: 7,
        patientName: 'Mario Rossi',
        getRange: getRange,
      );

  test('load fetches the default (today) range and resolves to success',
      () async {
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => Ok([_day(DateTime(2026, 6, 14))]));

    final vm = build();
    expect(vm.state.range.days, 1); // today
    await vm.load();

    expect(vm.state.days, isA<Success<List<PatientDiaryDay>>>());
    verify(() => getRange(7, any())).called(1);
  });

  test('setRange re-fetches with the new period', () async {
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => const Ok(<PatientDiaryDay>[]));

    final vm = build();
    await vm.load();

    vm.setRange(DiaryDateRange.last30());
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.range.days, 30);
    verify(() => getRange(any(), any())).called(2); // load + setRange
  });

  test('setNutrientFilter updates state only and never re-fetches', () async {
    when(() => getRange(any(), any()))
        .thenAnswer((_) async => const Ok(<PatientDiaryDay>[]));

    final vm = build();
    await vm.load();

    vm.setNutrientFilter(NutrientFilter.lactose);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.filter, NutrientFilter.lactose);
    verify(() => getRange(any(), any())).called(1); // only the initial load
  });

  test('the 92-day cap surfaces the validation message', () async {
    when(() => getRange(any(), any())).thenAnswer((_) async =>
        const Err(ValidationError('Il periodo non può superare 92 giorni')));

    final vm = build();
    await vm.load();

    expect(vm.state.days, isA<Failure<List<PatientDiaryDay>>>());
    expect(vm.state.error, 'Il periodo non può superare 92 giorni');
  });

  test('setRange cancels the previous in-flight fetch (last write wins)',
      () async {
    final slowFirst = Completer<Result<List<PatientDiaryDay>>>();
    final fastDays = [_day(DateTime(2026, 6, 1))];

    var call = 0;
    when(() => getRange(any(), any())).thenAnswer((_) {
      call++;
      // First fetch hangs; the second resolves immediately.
      return call == 1 ? slowFirst.future : Future.value(Ok(fastDays));
    });

    final vm = build();
    vm.setRange(DiaryDateRange.last7()); // token 1: hangs
    vm.setRange(DiaryDateRange.last30()); // token 2: resolves now
    await Future<void>.delayed(Duration.zero);

    expect((vm.state.days as Success<List<PatientDiaryDay>>).data, fastDays);

    // The stale first fetch completing late must be ignored.
    slowFirst.complete(Ok([_day(DateTime(2020, 1, 1))]));
    await Future<void>.delayed(Duration.zero);

    expect((vm.state.days as Success<List<PatientDiaryDay>>).data, fastDays);
    expect(vm.state.range.days, 30);
  });
}
