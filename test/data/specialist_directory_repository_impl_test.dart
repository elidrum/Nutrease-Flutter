import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/repository/specialist_directory_repository_impl.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/model/specialization_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordedRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;

  RecordedRequest(this.method, this.url, this.headers);
}

Map<String, Object?> _specialistRow(String cf,
        {String city = 'Roma', String spec = 'Nutrizionista'}) =>
    {
      'CodiceFiscale': cf,
      'Nome': 'Anna',
      'Cognome': 'Verdi',
      'Email': 'anna@example.com',
      'PartitaIVA': '12345678901',
      'Specializzazione': spec,
      'Citta': city,
      'Info': null,
    };

void main() {
  late List<RecordedRequest> requests;

  MockClient buildClient({
    List<Map<String, Object?>> specialisti = const [],
    List<Map<String, Object?>> fascicoli = const [],
  }) =>
      MockClient((request) async {
        requests.add(
            RecordedRequest(request.method, request.url, request.headers));
        final path = request.url.path;
        http.Response json(Object body) => http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
        if (path.endsWith('/specialista')) return json(specialisti);
        if (path.endsWith('/fascicoloclinico')) return json(fascicoli);
        return http.Response('', 204, request: request);
      });

  SpecialistDirectoryRepositoryImpl buildRepo(MockClient client) =>
      SpecialistDirectoryRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key', httpClient: client),
      );

  setUp(() => requests = []);

  group('searchSpecialists (RF13)', () {
    test('omits all filters when none are given', () async {
      final repo = buildRepo(buildClient(specialisti: [_specialistRow('A')]));

      final result = await repo.searchSpecialists(page: 0);
      expect(result, isA<Ok<List<Specialist>>>());
      expect((result as Ok<List<Specialist>>).value, hasLength(1));

      final get = requests.single;
      expect(get.url.queryParameters.containsKey('or'), isFalse);
      expect(get.url.queryParameters.containsKey('Specializzazione'), isFalse);
      expect(get.url.queryParameters.containsKey('Citta'), isFalse);
    });

    test('applies text (or name/surname), specialization and city filters',
        () async {
      final repo = buildRepo(buildClient(specialisti: const []));

      await repo.searchSpecialists(
        text: 'ros',
        specialization: SpecializationType.dietitian,
        city: 'Mil',
        page: 0,
      );

      final get = requests.single;
      // The `or` filter targets both name columns with ilike (encoding of the
      // `%` wildcard is left to postgrest; assert on the columns/operator).
      final orParam = get.url.queryParameters['or']!;
      expect(orParam, contains('Nome.ilike'));
      expect(orParam, contains('Cognome.ilike'));
      expect(orParam, contains('ros'));
      expect(get.url.queryParameters['Specializzazione'], 'eq.Dietista');
      expect(get.url.queryParameters['Citta'], startsWith('ilike.'));
      expect(get.url.queryParameters['Citta'], contains('Mil'));
    });

    test('requests the page window for the given page/pageSize', () async {
      final repo = buildRepo(buildClient(specialisti: const []));

      // page 1, pageSize 22 (20 base + 2 excluded) → offset 22, limit 22.
      await repo.searchSpecialists(page: 1, pageSize: 22);

      final params = requests.single.url.queryParameters;
      expect(params['offset'], '22');
      expect(params['limit'], '22');
    });
  });

  group('getLinkedSpecialist (RF13/RF14 delta)', () {
    test('decodes the embed for the active file', () async {
      final repo = buildRepo(buildClient(fascicoli: [
        {'IdFascicolo': 3, 'specialista': _specialistRow('SPC1')},
      ]));

      final result = await repo.getLinkedSpecialist('PAT1');
      expect(result, isA<Ok<Specialist?>>());
      final specialist = (result as Ok<Specialist?>).value;
      expect(specialist, isNotNull);
      expect(specialist!.taxCode, 'SPC1');
      expect(specialist.specialization, SpecializationType.nutritionist);

      final get = requests.single;
      expect(get.url.queryParameters['CodFiscalePaziente'], 'eq.PAT1');
      expect(get.url.queryParameters['Stato'], 'eq.Attivo');
      expect(get.url.query, contains('specialista'));
    });

    test('treats a null embed (de-verified, hidden by RLS) as "none"',
        () async {
      final repo = buildRepo(buildClient(fascicoli: [
        {'IdFascicolo': 3, 'specialista': null},
      ]));

      final result = await repo.getLinkedSpecialist('PAT1');
      expect(result, isA<Ok<Specialist?>>());
      expect((result as Ok<Specialist?>).value, isNull);
    });

    test('returns null when there is no active file', () async {
      final repo = buildRepo(buildClient(fascicoli: const []));

      final result = await repo.getLinkedSpecialist('PAT1');
      expect((result as Ok<Specialist?>).value, isNull);
    });
  });
}
