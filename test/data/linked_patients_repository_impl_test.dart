import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/repository/linked_patients_repository_impl.dart';
import 'package:nutrease_flutter/domain/model/linked_patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordedRequest {
  final String method;
  final Uri url;

  RecordedRequest(this.method, this.url);
}

void main() {
  late List<RecordedRequest> requests;

  Map<String, Object?> fascicoloRow({
    required int id,
    required String surname,
    String stato = 'Attivo',
  }) =>
      {
        'IdFascicolo': id,
        'Stato': stato,
        'paziente': {
          'CodiceFiscale': 'PAT$id',
          'Nome': 'Mario',
          'Cognome': surname,
          'Email': null,
          'DataNascita': null,
        },
      };

  MockClient buildClient(List<Map<String, Object?>> fascicoli) =>
      MockClient((request) async {
        requests.add(RecordedRequest(request.method, request.url));
        return http.Response(
          jsonEncode(fascicoli),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });

  LinkedPatientsRepositoryImpl buildRepo(MockClient client) =>
      LinkedPatientsRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key', httpClient: client),
      );

  setUp(() => requests = []);

  test('filters Stato=Attivo, embeds paziente, sorts by surname', () async {
    final repo = buildRepo(buildClient([
      fascicoloRow(id: 1, surname: 'Verdi'),
      fascicoloRow(id: 2, surname: 'bianchi'),
    ]));

    final result = await repo.getLinkedPatients();
    expect(result, isA<Ok<List<LinkedPatient>>>());
    final patients = (result as Ok<List<LinkedPatient>>).value;

    // Case-insensitive client-side sort by surname.
    expect(patients.map((p) => p.surname), ['bianchi', 'Verdi']);

    final get = requests.single;
    expect(get.method, 'GET');
    expect(get.url.path, endsWith('/fascicoloclinico'));
    expect(get.url.queryParameters['Stato'], 'eq.Attivo');
    expect(get.url.queryParameters['select'], contains('paziente'));
  });

  test('hits only fascicoloclinico — no new diary endpoints (ADR-0016)',
      () async {
    final repo = buildRepo(buildClient([fascicoloRow(id: 1, surname: 'Rossi')]));

    await repo.getLinkedPatients();

    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/fascicoloclinico'));
    expect(
      requests.any((r) =>
          r.url.path.endsWith('/pasto') || r.url.path.endsWith('/sintomo')),
      isFalse,
    );
  });

  test('drops a stray non-active row defensively', () async {
    final repo = buildRepo(buildClient([
      fascicoloRow(id: 1, surname: 'Rossi'),
      fascicoloRow(id: 2, surname: 'Neri', stato: 'Chiuso'),
    ]));

    final result = await repo.getLinkedPatients();
    final patients = (result as Ok<List<LinkedPatient>>).value;

    expect(patients.map((p) => p.surname), ['Rossi']);
  });
}
