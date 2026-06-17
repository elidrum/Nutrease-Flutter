import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/model/specialization_type.dart';
import 'package:nutrease_flutter/domain/usecase/get_excluded_specialist_tax_codes_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_linked_specialist_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/search_specialists_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/send_link_request_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/specialists/specialists_view_model.dart';

class _MockSearch extends Mock implements SearchSpecialistsUseCase {}

class _MockSend extends Mock implements SendLinkRequestUseCase {}

class _MockGetExcluded extends Mock
    implements GetExcludedSpecialistTaxCodesUseCase {}

class _MockGetLinked extends Mock implements GetLinkedSpecialistUseCase {}

const _s1 = Specialist(
    taxCode: 'CF1', firstName: 'Anna', surname: 'Verdi', email: '', vatNumber: '');
const _s2 = Specialist(
    taxCode: 'CF2', firstName: 'Bea', surname: 'Neri', email: '', vatNumber: '');
const _s3 = Specialist(
    taxCode: 'CF3', firstName: 'Carlo', surname: 'Bui', email: '', vatNumber: '');
const _linked = Specialist(
    taxCode: 'CFX',
    firstName: 'Mario',
    surname: 'Rossi',
    email: '',
    vatNumber: '');

void main() {
  late _MockSearch search;
  late _MockSend send;
  late _MockGetExcluded getExcluded;
  late _MockGetLinked getLinked;

  // The common "match any search call" matcher, reused across when()/verify().
  Future<Result<List<Specialist>>> anySearch() => search(
        text: any(named: 'text'),
        specialization: any(named: 'specialization'),
        city: any(named: 'city'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      );

  setUp(() {
    search = _MockSearch();
    send = _MockSend();
    getExcluded = _MockGetExcluded();
    getLinked = _MockGetLinked();

    when(anySearch).thenAnswer((_) async => const Ok(<Specialist>[]));
    when(() => getExcluded()).thenAnswer((_) async => const Ok(<String>{}));
    when(() => getLinked()).thenAnswer((_) async => const Ok<Specialist?>(null));
    when(() => send(any(), message: any(named: 'message')))
        .thenAnswer((_) async => const Ok<void>(null));
  });

  SpecialistsViewModel buildViewModel({int pageSize = 20}) =>
      SpecialistsViewModel(
        searchSpecialists: search,
        sendLinkRequest: send,
        getExcluded: getExcluded,
        getLinkedSpecialist: getLinked,
        pageSize: pageSize,
        debounceDuration: const Duration(milliseconds: 30),
      );

  group('search filters', () {
    test('debounces rapid text input into a single search', () async {
      final vm = buildViewModel();
      vm.setText('p');
      vm.setText('pa');
      vm.setText('pasta');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      verify(anySearch).called(1);
    });

    test('specialization dropdown searches immediately (no debounce)',
        () async {
      final vm = buildViewModel();
      vm.setSpecialization(SpecializationType.dietitian);
      // Well under the 30 ms debounce window: a call here proves immediacy.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      verify(anySearch).called(1);
    });
  });

  group('pagination + exclusions', () {
    test('infinite scroll loads page 2 and updates hasMore', () async {
      when(() => search(
            text: any(named: 'text'),
            specialization: any(named: 'specialization'),
            city: any(named: 'city'),
            page: any(named: 'page', that: equals(0)),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => const Ok([_s1, _s2]));
      when(() => search(
            text: any(named: 'text'),
            specialization: any(named: 'specialization'),
            city: any(named: 'city'),
            page: any(named: 'page', that: equals(1)),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => const Ok([_s3]));

      final vm = buildViewModel(pageSize: 2);
      await vm.init();
      expect(vm.state.items, [_s1, _s2]);
      expect(vm.state.hasMore, isTrue);
      expect(vm.state.page, 1);

      await vm.loadNextPage();
      expect(vm.state.items, [_s1, _s2, _s3]);
      expect(vm.state.hasMore, isFalse);
      expect(vm.state.page, 2);
    });

    test('exclusions filter results and grow the over-fetch size', () async {
      when(() => getExcluded()).thenAnswer((_) async => const Ok({'CF2'}));
      when(anySearch).thenAnswer((_) async => const Ok([_s1, _s2, _s3]));

      final vm = buildViewModel();
      await vm.init();

      expect(vm.state.items, [_s1, _s3]); // CF2 excluded

      final pageSizes = verify(() => search(
            text: any(named: 'text'),
            specialization: any(named: 'specialization'),
            city: any(named: 'city'),
            page: any(named: 'page'),
            pageSize: captureAny(named: 'pageSize'),
          )).captured;
      expect(pageSizes.last, 21); // 20 base + 1 excluded
    });
  });

  group('sendRequest (RF14)', () {
    test('removes the card and excludes the specialist on success', () async {
      when(anySearch).thenAnswer((_) async => const Ok([_s1]));

      final vm = buildViewModel();
      await vm.init();
      expect(vm.state.items, [_s1]);

      final ok = await vm.sendRequest('CF1', message: 'ciao');

      expect(ok, isTrue);
      expect(vm.state.items, isEmpty);
      verify(() => send('CF1', message: 'ciao')).called(1);
    });

    test('is single-flight', () async {
      when(anySearch).thenAnswer((_) async => const Ok([_s1]));
      when(() => send(any(), message: any(named: 'message')))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return const Ok<void>(null);
      });

      final vm = buildViewModel();
      await vm.init();
      final first = vm.sendRequest('CF1');
      final second = vm.sendRequest('CF1');
      await Future.wait([first, second]);

      verify(() => send(any(), message: any(named: 'message'))).called(1);
    });
  });

  group('linked specialist warning', () {
    test('linkedSpecialistName is populated from init', () async {
      when(() => getLinked())
          .thenAnswer((_) async => const Ok<Specialist?>(_linked));

      final vm = buildViewModel();
      await vm.init();

      expect(vm.state.linkedSpecialistName, 'Mario Rossi');
    });

    test('fetch is retried when the first attempt failed', () async {
      var calls = 0;
      when(() => getLinked()).thenAnswer((_) async =>
          calls++ == 0 ? const Err<Specialist?>(NetworkError()) : const Ok<Specialist?>(_linked));

      final vm = buildViewModel();
      await vm.init();
      expect(vm.state.linkedSpecialistName, isNull);

      await vm.ensureLinkedSpecialistLoaded();
      expect(vm.state.linkedSpecialistName, 'Mario Rossi');
    });
  });
}
