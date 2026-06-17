import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/age_policy.dart';

void main() {
  // Fixed "today" so the tests are deterministic (mirrors the Android suite).
  final now = DateTime(2026, 6, 8);

  group('AgePolicy.isValidBirthDate (minAge = 18)', () {
    test('rejects a future date', () {
      expect(
        AgePolicy.isValidBirthDate(DateTime(2030, 1, 1), now: now),
        isFalse,
      );
    });

    test('accepts someone who turns 18 exactly today', () {
      expect(
        AgePolicy.isValidBirthDate(DateTime(2008, 6, 8), now: now),
        isTrue,
      );
    });

    test('rejects someone the day before turning 18', () {
      // Turns 18 tomorrow → 17 today.
      expect(
        AgePolicy.isValidBirthDate(DateTime(2008, 6, 9), now: now),
        isFalse,
      );
    });

    test('accepts one day past the 18th birthday', () {
      expect(
        AgePolicy.isValidBirthDate(DateTime(2008, 6, 7), now: now),
        isTrue,
      );
    });

    test('rejects a 16-year-old', () {
      expect(
        AgePolicy.isValidBirthDate(DateTime(2010, 1, 1), now: now),
        isFalse,
      );
    });

    test('accepts a clearly adult birth date', () {
      expect(
        AgePolicy.isValidBirthDate(DateTime(1990, 1, 1), now: now),
        isTrue,
      );
    });

    test('handles a leap-day birth on a non-leap year', () {
      // Born 29/02/2008: still 17 on 28/02/2026, 18 from 01/03/2026.
      expect(
        AgePolicy.isValidBirthDate(DateTime(2008, 2, 29),
            now: DateTime(2026, 2, 28)),
        isFalse,
      );
      expect(
        AgePolicy.isValidBirthDate(DateTime(2008, 2, 29),
            now: DateTime(2026, 3, 1)),
        isTrue,
      );
    });
  });
}
