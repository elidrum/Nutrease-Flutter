import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/local/diary_cache_dao.dart';
import 'package:nutrease_flutter/data/repository/symptom_repository_impl.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/in_memory_cache.dart';

/// One recorded PostgREST call.
class RecordedRequest {
  final String method;
  final Uri url;
  final String body;

  RecordedRequest(this.method, this.url, this.body);
}

/// Two `sintomo` rows for the `getSymptomsForDate` query.
const List<Map<String, Object?>> _symptomsForDateResponse = [
  {
    'IdSintomo': 1,
    'IdFascicolo': 3,
    'Data': '2026-06-12',
    'Ora': '09:00:00',
    'Descrizione': 'Crampi',
    'Intensita': 9, // → severe
  },
  {
    'IdSintomo': 2,
    'IdFascicolo': 3,
    'Data': '2026-06-12',
    'Ora': '14:00:00',
    'Descrizione': 'Gonfiore',
    'Intensita': 6, // → moderate
  },
];

void main() {
  late List<RecordedRequest> requests;
  late SymptomRepositoryImpl repository;

  final symptom = Symptom(
    fascicoloId: 3,
    date: DateTime(2026, 6, 12),
    time: '09:00:00',
    type: SymptomType.cramps,
    severity: SymptomSeverity.severe,
  );

  /// Routes every PostgREST request to a canned response and records it.
  MockClient buildClient() => MockClient((request) async {
        requests.add(RecordedRequest(
            request.method, request.url, utf8.decode(request.bodyBytes)));
        final path = request.url.path;
        final wantsSingleObject =
            request.headers['Accept']?.contains('vnd.pgrst.object') ?? false;

        if (request.method == 'POST' && path.endsWith('/sintomo')) {
          return http.Response(
            wantsSingleObject ? '{"IdSintomo": 7}' : '[{"IdSintomo": 7}]',
            201,
            headers: {'content-type': 'application/json'},
            // postgrest reads response.request to pick the parsing strategy.
            request: request,
          );
        }
        if (request.method == 'GET' && path.endsWith('/sintomo')) {
          return http.Response(
            jsonEncode(_symptomsForDateResponse),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response('', 204, request: request);
      });

  setUp(() {
    requests = [];
    repository = SymptomRepositoryImpl(
      SupabaseClient('http://localhost:54321', 'anon-key',
          httpClient: buildClient()),
      buildInMemoryCacheDao(),
    );
  });

  group('addSymptom', () {
    test('inserts the sintomo and returns the new id', () async {
      final result = await repository.addSymptom(symptom);

      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, 7);

      final insert = requests
          .firstWhere((r) => r.method == 'POST' && r.url.path.endsWith('/sintomo'));
      final body = jsonDecode(insert.body) as Map<String, dynamic>;
      expect(body['IdFascicolo'], 3);
      expect(body['Data'], '2026-06-12');
      expect(body['Descrizione'], 'Crampi');
      expect(body['Intensita'], 9);
      expect(body.containsKey('IdSintomo'), isFalse,
          reason: 'bigserial assigns the id');
    });
  });

  group('getSymptomsForDate', () {
    test('maps and orders the rows for the day', () async {
      final result = await repository.getSymptomsForDate(3, DateTime(2026, 6, 12));

      expect(result, isA<Ok<List<Symptom>>>());
      final symptoms = (result as Ok<List<Symptom>>).value;
      expect(symptoms, hasLength(2));
      expect(symptoms.first.type, SymptomType.cramps);
      expect(symptoms.first.severity, SymptomSeverity.severe);

      final get = requests.firstWhere(
          (r) => r.method == 'GET' && r.url.path.endsWith('/sintomo'));
      expect(get.url.queryParameters['IdFascicolo'], 'eq.3');
      expect(get.url.queryParameters['Data'], 'eq.2026-06-12');
      expect(get.url.queryParameters['order'], contains('Ora'));
    });
  });

  group('deleteSymptom', () {
    test('deletes the sintomo filtered by id', () async {
      final result = await repository.deleteSymptom(7);

      expect(result, isA<Ok<void>>());
      final del = requests.firstWhere(
          (r) => r.method == 'DELETE' && r.url.path.endsWith('/sintomo'));
      expect(del.url.queryParameters['IdSintomo'], 'eq.7');
    });
  });

  group('offline cache fallback (RF11)', () {
    SymptomRepositoryImpl offlineRepoWith(DiaryCacheDao dao) =>
        SymptomRepositoryImpl(
          SupabaseClient('http://localhost:54321', 'anon-key',
              httpClient: MockClient((request) async =>
                  http.Response('boom', 500, request: request))),
          dao,
        );

    test('returns the cached day when the network fails', () async {
      final dao = buildInMemoryCacheDao();
      final date = DateTime(2026, 6, 12);
      final cached = Symptom(
        id: 1,
        fascicoloId: 3,
        date: date,
        time: '09:00:00',
        type: SymptomType.cramps,
        severity: SymptomSeverity.severe,
      );
      await dao.replaceSymptoms(3, date, [cached]);

      final result = await offlineRepoWith(dao).getSymptomsForDate(3, date);

      expect(result, isA<Ok<List<Symptom>>>());
      final symptoms = (result as Ok<List<Symptom>>).value;
      expect(symptoms.single.id, 1);
      expect(symptoms.single.type, SymptomType.cramps);
    });

    test('serves an empty list for a synced day with no symptoms', () async {
      final dao = buildInMemoryCacheDao();
      final date = DateTime(2026, 6, 12);
      // Giornata già scaricata ma senza sintomi: marcata sincronizzata, quindi
      // offline deve dare Ok([]), non un errore.
      await dao.replaceSymptoms(3, date, const []);

      final result = await offlineRepoWith(dao).getSymptomsForDate(3, date);

      expect(result, isA<Ok<List<Symptom>>>());
      expect((result as Ok<List<Symptom>>).value, isEmpty);
    });

    test('returns an error when the day was never synced', () async {
      final dao = buildInMemoryCacheDao();

      final result =
          await offlineRepoWith(dao).getSymptomsForDate(3, DateTime(2026, 6, 12));

      expect(result, isA<Err<List<Symptom>>>());
    });
  });
}
