import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/linked_patient_dto.dart';
import 'package:nutrease_flutter/data/mapper/linked_patient_mapper.dart';

void main() {
  Map<String, dynamic> row({
    String stato = 'Attivo',
    Map<String, dynamic>? paziente = const {
      'CodiceFiscale': 'PAT00000000000001',
      'Nome': 'Mario',
      'Cognome': 'Rossi',
      'Email': 'mario@e.it',
      'DataNascita': '1990-05-20',
    },
  }) =>
      {'IdFascicolo': 42, 'Stato': stato, 'paziente': paziente};

  test('maps the paziente embed IT→EN for an active file', () {
    final patient =
        LinkedPatientDto.fromJson(row()).toDomainIfActive();

    expect(patient, isNotNull);
    expect(patient!.fascicoloId, 42);
    expect(patient.taxCode, 'PAT00000000000001');
    expect(patient.firstName, 'Mario');
    expect(patient.surname, 'Rossi');
    expect(patient.email, 'mario@e.it');
    expect(patient.birthDate, DateTime(1990, 5, 20));
    expect(patient.fullName, 'Mario Rossi');
  });

  test('drops a non-active file (Stato != Attivo)', () {
    final patient =
        LinkedPatientDto.fromJson(row(stato: 'Chiuso')).toDomainIfActive();
    expect(patient, isNull);
  });

  test('drops a row whose patient embed is missing', () {
    final patient =
        LinkedPatientDto.fromJson(row(paziente: null)).toDomainIfActive();
    expect(patient, isNull);
  });

  test('a missing birth date maps to null', () {
    final patient = LinkedPatientDto.fromJson(row(paziente: const {
      'CodiceFiscale': 'PAT00000000000002',
      'Nome': 'Lucia',
      'Cognome': 'Bianchi',
      'Email': null,
      'DataNascita': null,
    })).toDomainIfActive();

    expect(patient, isNotNull);
    expect(patient!.birthDate, isNull);
    expect(patient.email, isNull);
  });
}
