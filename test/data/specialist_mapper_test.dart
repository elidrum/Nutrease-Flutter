import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/specialist_dto.dart';
import 'package:nutrease_flutter/data/mapper/specialist_mapper.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/model/specialization_type.dart';

void main() {
  group('SpecialistDto <-> Specialist mapping', () {
    test('maps DB (IT) fields and specialization enum to the domain model', () {
      final dto = SpecialistDto.fromJson({
        'CodiceFiscale': 'BNCLRA85B45F205X',
        'Nome': 'Laura',
        'Cognome': 'Bianchi',
        'Email': 'laura@example.com',
        'PartitaIVA': '12345678901',
        'Specializzazione': 'Gastroenterologo',
        'Citta': 'Torino',
        'Info': 'Studio centro',
      });

      final specialist = dto.toDomain();

      expect(specialist.taxCode, 'BNCLRA85B45F205X');
      expect(specialist.firstName, 'Laura');
      expect(specialist.surname, 'Bianchi');
      expect(specialist.vatNumber, '12345678901');
      expect(specialist.specialization, SpecializationType.gastroenterologist);
      expect(specialist.city, 'Torino');
      expect(specialist.info, 'Studio centro');
    });

    test('maps a null/unknown specialization to null', () {
      final dto = SpecialistDto.fromJson({
        'CodiceFiscale': 'CF',
        'Nome': 'N',
        'Cognome': 'C',
        'Email': null,
        'PartitaIVA': '00000000000',
        'Specializzazione': null,
        'Citta': null,
        'Info': null,
      });

      expect(dto.toDomain().specialization, isNull);
      expect(dto.toDomain().email, '');
    });

    test('round-trips the specialization label back to the DB shape', () {
      const specialist = Specialist(
        taxCode: 'CF',
        firstName: 'A',
        surname: 'B',
        email: 'a@b.com',
        vatNumber: '11111111111',
        specialization: SpecializationType.dietitian,
        city: 'Bari',
        info: null,
      );

      final json = specialist.toDto().toJson();

      expect(json['Specializzazione'], 'Dietista');
      expect(json['PartitaIVA'], '11111111111');
    });
  });
}
