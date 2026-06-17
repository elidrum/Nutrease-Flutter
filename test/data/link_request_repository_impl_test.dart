import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/repository/link_request_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One recorded PostgREST call.
class RecordedRequest {
  final String method;
  final Uri url;
  final String body;
  final Map<String, String> headers;

  RecordedRequest(this.method, this.url, this.body, this.headers);
}

void main() {
  late List<RecordedRequest> requests;
  late LinkRequestRepositoryImpl repository;

  /// Maps each PostgREST path to a canned response and records the request.
  MockClient buildClient({
    List<Map<String, Object?>> profilo = const [
      {'codice_fiscale': 'PAT00000000000001'}
    ],
    List<Map<String, Object?>> received = const [],
    List<Map<String, Object?>> fascicoli = const [],
    List<Map<String, Object?>> pending = const [],
  }) =>
      MockClient((request) async {
        requests.add(RecordedRequest(request.method, request.url,
            utf8.decode(request.bodyBytes), request.headers));
        final path = request.url.path;

        http.Response json(Object body) => http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );

        if (path.endsWith('/profilo_utente')) return json(profilo);
        if (path.endsWith('/richiesta_collegamento')) {
          if (request.method == 'GET') {
            // Inbox selects the `paziente` embed; exclusions select only CFs.
            final isInbox =
                request.url.queryParameters['select']?.contains('paziente') ??
                    false;
            return json(isInbox ? received : pending);
          }
          if (request.method == 'POST') return json(const []); // upsert
          return http.Response('', 204, request: request); // PATCH update
        }
        if (path.endsWith('/fascicoloclinico')) return json(fascicoli);
        return http.Response('', 204, request: request);
      });

  LinkRequestRepositoryImpl buildRepo(MockClient client) =>
      LinkRequestRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key', httpClient: client),
      );

  setUp(() => requests = []);

  group('sendLinkRequest (RF14, ADR-0023 upsert)', () {
    test('upserts on the unique pair with the response fields reset', () async {
      repository = buildRepo(buildClient());

      final result = await repository.sendLinkRequest('SPC00000000000009',
          message: 'Buongiorno');

      expect(result, isA<Ok<void>>());

      final upsert = requests.firstWhere((r) =>
          r.method == 'POST' && r.url.path.endsWith('/richiesta_collegamento'));
      final body = jsonDecode(upsert.body) as Map<String, dynamic>;
      expect(body['CodFiscalePaziente'], 'PAT00000000000001');
      expect(body['CodFiscaleSpecialista'], 'SPC00000000000009');
      expect(body['Stato'], 'In Attesa');
      expect(body['MessaggioRichiesta'], 'Buongiorno');
      // Re-send after a rejection must clear the response fields (chk_risposta).
      expect(body.containsKey('DataRisposta'), isTrue);
      expect(body['DataRisposta'], isNull);
      expect(body.containsKey('MotivazioneRifiuto'), isTrue);
      expect(body['MotivazioneRifiuto'], isNull);

      // Upsert semantics: merge-duplicates + on_conflict on the unique pair.
      expect(upsert.headers['Prefer'], contains('resolution=merge-duplicates'));
      expect(upsert.url.query, contains('on_conflict'));
      expect(Uri.decodeComponent(upsert.url.query),
          contains('CodFiscalePaziente,CodFiscaleSpecialista'));
    });

    test('resolves the patient tax code from profilo_utente first', () async {
      repository = buildRepo(buildClient());
      await repository.sendLinkRequest('SPC00000000000009');

      expect(
        requests.any(
            (r) => r.method == 'GET' && r.url.path.endsWith('/profilo_utente')),
        isTrue,
      );
    });
  });

  group('acceptLinkRequest (RF16)', () {
    test('updates Stato=Accettata with a DataRisposta, filtered by id',
        () async {
      repository = buildRepo(buildClient());

      final result = await repository.acceptLinkRequest(55);
      expect(result, isA<Ok<void>>());

      final patch = requests.firstWhere((r) =>
          r.method == 'PATCH' && r.url.path.endsWith('/richiesta_collegamento'));
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(body['Stato'], 'Accettata');
      expect(body['DataRisposta'], isNotNull);
      expect(body.containsKey('MotivazioneRifiuto'), isFalse);
      expect(patch.url.queryParameters['IdRichiesta'], 'eq.55');
    });
  });

  group('rejectLinkRequest (RF17)', () {
    test('updates Stato=Rifiutata with reason + DataRisposta', () async {
      repository = buildRepo(buildClient());

      final result = await repository.rejectLinkRequest(77, 'Agenda piena');
      expect(result, isA<Ok<void>>());

      final patch = requests.firstWhere((r) =>
          r.method == 'PATCH' && r.url.path.endsWith('/richiesta_collegamento'));
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(body['Stato'], 'Rifiutata');
      expect(body['DataRisposta'], isNotNull);
      expect(body['MotivazioneRifiuto'], 'Agenda piena');
      expect(patch.url.queryParameters['IdRichiesta'], 'eq.77');
    });
  });

  group('getReceivedLinkRequests (RF15)', () {
    test('filters pending, orders by date desc, maps the embed', () async {
      repository = buildRepo(buildClient(received: [
        {
          'IdRichiesta': 1,
          'CodFiscalePaziente': 'PAT00000000000001',
          'CodFiscaleSpecialista': 'SPC00000000000001',
          'Stato': 'In Attesa',
          'MessaggioRichiesta': 'Ciao',
          'DataRichiesta': '2026-06-13T10:00:00Z',
          'DataRisposta': null,
          'MotivazioneRifiuto': null,
          'paziente': {
            'Nome': 'Mario',
            'Cognome': 'Rossi',
            'DataNascita': '1990-01-15',
          },
        },
      ]));

      final result = await repository.getReceivedLinkRequests();
      expect(result, isA<Ok>());
      final items = (result as Ok).value;
      expect(items, hasLength(1));
      expect(items.first.patientFullName, 'Mario Rossi');

      final get = requests.firstWhere((r) =>
          r.method == 'GET' && r.url.path.endsWith('/richiesta_collegamento'));
      expect(get.url.queryParameters['Stato'], 'eq.In Attesa');
      expect(get.url.queryParameters['order'], contains('DataRichiesta'));
      expect(get.url.queryParameters['order'], contains('desc'));
      expect(get.url.query, contains('paziente'));
    });
  });

  group('getExcludedSpecialistTaxCodes', () {
    test('unions active fascicoli with pending requests', () async {
      repository = buildRepo(buildClient(
        fascicoli: [
          {'CodFiscaleSpecialista': 'SPC00000000000001'},
        ],
        pending: [
          {'CodFiscaleSpecialista': 'SPC00000000000002'},
          {'CodFiscaleSpecialista': 'SPC00000000000001'}, // duplicate
        ],
      ));

      final result = await repository.getExcludedSpecialistTaxCodes();
      expect(result, isA<Ok<Set<String>>>());
      final excluded = (result as Ok<Set<String>>).value;
      expect(excluded, {'SPC00000000000001', 'SPC00000000000002'});

      expect(
        requests.firstWhere(
            (r) => r.url.path.endsWith('/fascicoloclinico'))
            .url
            .queryParameters['Stato'],
        'eq.Attivo',
      );
      expect(
        requests
            .lastWhere((r) => r.url.path.endsWith('/richiesta_collegamento'))
            .url
            .queryParameters['Stato'],
        'eq.In Attesa',
      );
    });
  });
}
