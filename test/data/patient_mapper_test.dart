import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/patient_dto.dart';
import 'package:nutrease_flutter/data/mapper/patient_mapper.dart';
import 'package:nutrease_flutter/domain/model/gender.dart';
import 'package:nutrease_flutter/domain/model/patient.dart';

void main() {
  group('PatientDto <-> Patient mapping', () {
    test('maps DB (IT) fields to the domain (EN) model', () {
      final dto = PatientDto.fromJson({
        'CodiceFiscale': 'RSSMRA80A01H501U',
        'Nome': 'Mario',
        'Cognome': 'Rossi',
        'Email': 'mario@example.com',
        'Sesso': 'F',
        'DataNascita': '1980-01-05',
        'Telefono': '+390000000',
        'Citta': 'Roma',
      });

      final patient = dto.toDomain();

      expect(patient.taxCode, 'RSSMRA80A01H501U');
      expect(patient.firstName, 'Mario');
      expect(patient.surname, 'Rossi');
      expect(patient.email, 'mario@example.com');
      expect(patient.gender, Gender.female);
      expect(patient.birthDate, DateTime(1980, 1, 5));
      expect(patient.phone, '+390000000');
      expect(patient.city, 'Roma');
    });

    test('maps unknown Sesso to Gender.other and tolerates null email', () {
      final dto = PatientDto.fromJson({
        'CodiceFiscale': 'X',
        'Nome': 'N',
        'Cognome': 'C',
        'Email': null,
        'Sesso': 'Altro',
        'DataNascita': '2000-12-31',
        'Telefono': null,
        'Citta': null,
      });

      final patient = dto.toDomain();

      expect(patient.gender, Gender.other);
      expect(patient.email, '');
      expect(patient.phone, isNull);
    });

    test('round-trips gender and birth date back to the DB shape', () {
      final patient = Patient(
        taxCode: 'CF',
        firstName: 'A',
        surname: 'B',
        email: 'a@b.com',
        birthDate: DateTime(1995, 3, 7),
        gender: Gender.male,
        phone: null,
        city: 'Napoli',
      );

      final json = patient.toDto().toJson();

      expect(json['Sesso'], 'M');
      expect(json['DataNascita'], '1995-03-07');
      expect(json['Citta'], 'Napoli');
    });
  });
}
