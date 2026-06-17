import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/data/repository/auth_repository_impl.dart';
import 'package:nutrease_flutter/data/repository/supabase_error_mapper.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
// Hide the SDK's `AuthUser` so it doesn't clash with the domain model.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  group('mapSupabaseError', () {
    test('maps an auth API exception to a generic AuthError', () {
      expect(
        mapSupabaseError(AuthApiException('Invalid login credentials')),
        isA<AuthError>(),
      );
    });

    test('maps a transport (socket) exception to NetworkError', () {
      expect(
        mapSupabaseError(const SocketException('no route')),
        isA<NetworkError>(),
      );
    });

    test('maps a retryable auth fetch exception to NetworkError', () {
      expect(
        mapSupabaseError(AuthRetryableFetchException()),
        isA<NetworkError>(),
      );
    });

    test('maps an unknown error to UnknownError', () {
      expect(mapSupabaseError(Exception('boom')), isA<UnknownError>());
    });
  });

  group('AuthRepositoryImpl.login', () {
    late _MockSupabaseClient client;
    late _MockGoTrueClient auth;
    late AuthRepositoryImpl repository;

    setUp(() {
      client = _MockSupabaseClient();
      auth = _MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      repository = AuthRepositoryImpl(client);
    });

    test('maps wrong credentials to a generic AuthError', () async {
      when(() => auth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthApiException('Invalid login credentials'));

      final result = await repository.login('user@example.com', 'wrong');

      expect(result, isA<Err<AuthUser>>());
      expect((result as Err<AuthUser>).error, isA<AuthError>());
    });

    test('maps a network failure to NetworkError', () async {
      when(() => auth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const SocketException('offline'));

      final result = await repository.login('user@example.com', 'secret');

      expect(result, isA<Err<AuthUser>>());
      expect((result as Err<AuthUser>).error, isA<NetworkError>());
    });
  });

  group('AuthRepositoryImpl.deleteAccount (RPC delete_own_account, ADR-0024)', () {
    // Real SupabaseClient over a MockClient so the `rpc()` call hits the wire
    // and we assert the mapping of the function's textual outcome.
    AuthRepositoryImpl repoReturning(String outcome) {
      final client = MockClient((request) async => http.Response(
            jsonEncode(outcome),
            200,
            headers: const {'content-type': 'application/json'},
            request: request,
          ));
      return AuthRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key', httpClient: client),
      );
    }

    test('maps "deleted" to Ok', () async {
      final result = await repoReturning('deleted').deleteAccount();
      expect(result, isA<Ok<void>>());
    });

    test('maps "has_linked_patients" to a ValidationError', () async {
      final result = await repoReturning('has_linked_patients').deleteAccount();
      expect((result as Err<void>).error, isA<ValidationError>());
    });

    test('maps "not_authenticated" to a generic AuthError', () async {
      final result = await repoReturning('not_authenticated').deleteAccount();
      expect((result as Err<void>).error, isA<AuthError>());
    });

    test('calls the delete_own_account RPC endpoint', () async {
      late Uri seen;
      final client = MockClient((request) async {
        seen = request.url;
        return http.Response(jsonEncode('deleted'), 200,
            headers: const {'content-type': 'application/json'},
            request: request);
      });
      final repo = AuthRepositoryImpl(
        SupabaseClient('http://localhost:54321', 'anon-key', httpClient: client),
      );
      await repo.deleteAccount();
      expect(seen.path, endsWith('/rpc/delete_own_account'));
    });
  });
}
