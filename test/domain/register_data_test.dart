import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/domain/model/gender.dart';
import 'package:nutrease_flutter/domain/model/register_data.dart';
import 'package:nutrease_flutter/domain/model/specialization_type.dart';

void main() {
  group('RegisterData.toAuthMetadata', () {
    test('patient produces exactly the trigger keys', () {
      final data = PatientRegisterData(
        email: 'mario@example.com',
        password: 'Password1',
        firstName: 'Mario',
        surname: 'Rossi',
        taxCode: 'RSSMRA80A01H501U',
        gender: Gender.male,
        birthDate: DateTime(1980, 1, 5),
      );

      final meta = data.toAuthMetadata();

      expect(
        meta.keys.toSet(),
        {'codice_fiscale', 'nome', 'cognome', 'ruolo', 'sesso', 'data_nascita'},
      );
      expect(meta['ruolo'], 'paziente');
      expect(meta['codice_fiscale'], 'RSSMRA80A01H501U');
      expect(meta['nome'], 'Mario');
      expect(meta['cognome'], 'Rossi');
      expect(meta['sesso'], 'M');
      expect(meta['data_nascita'], '1980-01-05');
    });

    test('specialist produces exactly the trigger keys', () {
      const data = SpecialistRegisterData(
        email: 'lab@example.com',
        password: 'Password1',
        firstName: 'Laura',
        surname: 'Bianchi',
        taxCode: 'BNCLRA85B45F205X',
        vatNumber: '12345678901',
        specialization: SpecializationType.nutritionist,
        city: 'Milano',
      );

      final meta = data.toAuthMetadata();

      expect(
        meta.keys.toSet(),
        {
          'codice_fiscale',
          'nome',
          'cognome',
          'ruolo',
          'partita_iva',
          'specializzazione',
          'citta',
        },
      );
      expect(meta['ruolo'], 'specialista');
      expect(meta['partita_iva'], '12345678901');
      expect(meta['specializzazione'], 'Nutrizionista');
      expect(meta['citta'], 'Milano');
    });
  });
}
