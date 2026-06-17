import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';

void main() {
  group('toIntensity (write: 1/3/6/9)', () {
    test('maps each level to its canonical intensity', () {
      expect(SymptomSeverity.toIntensity(SymptomSeverity.none), 1);
      expect(SymptomSeverity.toIntensity(SymptomSeverity.mild), 3);
      expect(SymptomSeverity.toIntensity(SymptomSeverity.moderate), 6);
      expect(SymptomSeverity.toIntensity(SymptomSeverity.severe), 9);
    });
  });

  group('fromIntensity (read: buckets at 2/4/7, Android parity)', () {
    test('bucketizes the boundaries correctly', () {
      // none: 1..2
      expect(SymptomSeverity.fromIntensity(1), SymptomSeverity.none);
      expect(SymptomSeverity.fromIntensity(2), SymptomSeverity.none);
      // mild: 3..4
      expect(SymptomSeverity.fromIntensity(3), SymptomSeverity.mild);
      expect(SymptomSeverity.fromIntensity(4), SymptomSeverity.mild);
      // moderate: 5..7
      expect(SymptomSeverity.fromIntensity(5), SymptomSeverity.moderate);
      expect(SymptomSeverity.fromIntensity(7), SymptomSeverity.moderate);
      // severe: 8..10
      expect(SymptomSeverity.fromIntensity(8), SymptomSeverity.severe);
      expect(SymptomSeverity.fromIntensity(10), SymptomSeverity.severe);
    });

    test('round-trips the canonical write values', () {
      for (final level in SymptomSeverity.values) {
        expect(
          SymptomSeverity.fromIntensity(SymptomSeverity.toIntensity(level)),
          level,
        );
      }
    });
  });
}
