import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/symptom_dto.dart';
import 'package:nutrease_flutter/data/mapper/symptom_mapper.dart';
import 'package:nutrease_flutter/domain/model/symptom.dart';
import 'package:nutrease_flutter/domain/model/symptom_severity.dart';
import 'package:nutrease_flutter/domain/model/symptom_type.dart';

void main() {
  group('toDto (write)', () {
    test('maps type → capitalized Descrizione and severity → 1/3/6/9', () {
      const cases = {
        SymptomType.bloating: 'Gonfiore',
        SymptomType.cramps: 'Crampi',
        SymptomType.diarrhea: 'Diarrea',
        SymptomType.constipation: 'Stitichezza',
        SymptomType.nausea: 'Nausea',
        SymptomType.reflux: 'Reflusso',
        SymptomType.other: 'Altro',
      };
      cases.forEach((type, label) {
        final dto = Symptom(
          fascicoloId: 3,
          date: DateTime(2026, 6, 12),
          time: '09:00:00',
          type: type,
          severity: SymptomSeverity.moderate,
        ).toDto();
        expect(dto.descrizione, label);
        expect(dto.intensita, 6);
      });
    });

    test('other writes the free-text label into Descrizione', () {
      final dto = Symptom(
        fascicoloId: 3,
        date: DateTime(2026, 6, 12),
        time: '09:00:00',
        type: SymptomType.other,
        severity: SymptomSeverity.mild,
        otherDescription: 'Mal di testa',
      ).toDto();
      expect(dto.descrizione, 'Mal di testa');
    });

    test('other without free text falls back to the "Altro" label', () {
      final dto = Symptom(
        fascicoloId: 3,
        date: DateTime(2026, 6, 12),
        time: '09:00:00',
        type: SymptomType.other,
        severity: SymptomSeverity.mild,
      ).toDto();
      expect(dto.descrizione, 'Altro');
    });

    test('writes the date as yyyy-MM-dd and omits the id (bigserial)', () {
      final dto = Symptom(
        fascicoloId: 3,
        date: DateTime(2026, 6, 12),
        time: '09:00:00',
        type: SymptomType.nausea,
        severity: SymptomSeverity.severe,
      ).toDto();
      expect(dto.data, '2026-06-12');
      expect(dto.intensita, 9);
      expect(dto.toJson().containsKey('IdSintomo'), isFalse);
    });
  });

  group('fromDto (read)', () {
    test('maps Descrizione → type and bucketizes Intensita', () {
      final symptom = symptomFromDto(const SymptomDto(
        idSintomo: 5,
        idFascicolo: 3,
        data: '2026-06-12',
        ora: '09:00:00',
        descrizione: 'Crampi',
        intensita: 7, // → moderate (bucket 5..7)
      ));
      expect(symptom.id, 5);
      expect(symptom.type, SymptomType.cramps);
      expect(symptom.severity, SymptomSeverity.moderate);
    });

    test('reads the Descrizione case-insensitively', () {
      final symptom = symptomFromDto(const SymptomDto(
        idFascicolo: 3,
        data: '2026-06-12',
        ora: '09:00:00',
        descrizione: 'gonfiore',
        intensita: 3,
      ));
      expect(symptom.type, SymptomType.bloating);
    });

    test('unknown Descrizione falls back to other and keeps the free text', () {
      final symptom = symptomFromDto(const SymptomDto(
        idFascicolo: 3,
        data: '2026-06-12',
        ora: '09:00:00',
        descrizione: 'Mal di testa',
        intensita: 1,
      ));
      expect(symptom.type, SymptomType.other);
      expect(symptom.otherDescription, 'Mal di testa');
    });

    test('normalizes a time with microseconds to HH:mm:ss', () {
      final symptom = symptomFromDto(const SymptomDto(
        idFascicolo: 3,
        data: '2026-06-12',
        ora: '09:00:00.123456',
        descrizione: 'Nausea',
        intensita: 1,
      ));
      expect(symptom.time, '09:00:00');
    });
  });
}
