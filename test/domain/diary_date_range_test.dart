import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/diary_date_range.dart';

void main() {
  group('DiaryDateRange.days', () {
    test('today() spans a single day', () {
      expect(DiaryDateRange.today().days, 1);
    });

    test('last7() spans 7 days', () {
      expect(DiaryDateRange.last7().days, 7);
    });

    test('last30() spans 30 days', () {
      expect(DiaryDateRange.last30().days, 30);
    });

    test('custom() counts the inclusive span', () {
      final range =
          DiaryDateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 10));
      expect(range.days, 10);
    });
  });

  group('92-day cap (ADR-0017)', () {
    test('exactly 92 days is within the cap', () {
      final from = DateTime(2026, 1, 1);
      final range = DiaryDateRange.custom(from, from.add(const Duration(days: 91)));
      expect(range.days, 92);
      expect(range.exceedsCap, isFalse);
    });

    test('93 days exceeds the cap', () {
      final from = DateTime(2026, 1, 1);
      final range = DiaryDateRange.custom(from, from.add(const Duration(days: 92)));
      expect(range.days, 93);
      expect(range.exceedsCap, isTrue);
    });
  });

  group('normalization', () {
    test('strips the time component from the bounds', () {
      final range = DiaryDateRange.custom(
        DateTime(2026, 3, 4, 23, 59),
        DateTime(2026, 3, 6, 1, 30),
      );
      expect(range.from, DateTime(2026, 3, 4));
      expect(range.to, DateTime(2026, 3, 6));
      expect(range.days, 3);
    });

    test('reorders swapped bounds', () {
      final range =
          DiaryDateRange.custom(DateTime(2026, 5, 10), DateTime(2026, 5, 1));
      expect(range.from, DateTime(2026, 5, 1));
      expect(range.to, DateTime(2026, 5, 10));
    });
  });

  group('dates', () {
    test('lists every inclusive date ascending, date-only', () {
      final range =
          DiaryDateRange.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 12));
      expect(range.dates, [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 12),
      ]);
    });

    test('a single-day range yields one date', () {
      final range =
          DiaryDateRange.custom(DateTime(2026, 6, 10), DateTime(2026, 6, 10));
      expect(range.dates, [DateTime(2026, 6, 10)]);
    });

    test('spans a month boundary correctly', () {
      final range =
          DiaryDateRange.custom(DateTime(2026, 1, 30), DateTime(2026, 2, 2));
      expect(range.dates, [
        DateTime(2026, 1, 30),
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 2),
      ]);
    });
  });
}
