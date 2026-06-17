import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';

void main() {
  group('DomainError', () {
    const errors = <DomainError>[
      NetworkError(),
      AuthError(),
      ValidationError('Campo obbligatorio.'),
      NotFoundError(),
      UnknownError(),
    ];

    test('every variant exposes a non-empty Italian message', () {
      for (final error in errors) {
        expect(error.message, isNotEmpty);
      }
    });

    test('AuthError stays generic (no field disclosure)', () {
      const error = AuthError();
      expect(error.message, 'Credenziali non valide.');
      expect(error.message.toLowerCase(), isNot(contains('email')));
      expect(error.message.toLowerCase(), isNot(contains('password')));
    });
  });
}
