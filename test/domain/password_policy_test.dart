import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/password_policy.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('rejects an empty password as too short', () {
      expect(PasswordPolicy.validate(''), contains('8 caratteri'));
    });

    test('rejects a password shorter than 8 characters', () {
      expect(PasswordPolicy.validate('Ab1cd'), contains('8 caratteri'));
    });

    test('rejects a password without an uppercase letter', () {
      expect(PasswordPolicy.validate('password1'), contains('maiuscola'));
    });

    test('rejects a password without a digit', () {
      expect(PasswordPolicy.validate('Password'), contains('cifra'));
    });

    test('accepts a compliant password', () {
      expect(PasswordPolicy.validate('Password1'), isNull);
    });
  });
}
