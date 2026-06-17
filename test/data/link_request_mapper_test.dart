import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/data/dto/link_request_dto.dart';
import 'package:nutrease_flutter/data/mapper/link_request_mapper.dart';
import 'package:nutrease_flutter/domain/model/link_request_status.dart';

void main() {
  group('LinkRequestDto.toDomain', () {
    LinkRequestDto dto({
      String stato = 'In Attesa',
      String? dataRisposta,
      String? motivazione,
      String? messaggio = 'Ciao',
    }) =>
        LinkRequestDto(
          idRichiesta: 42,
          codFiscalePaziente: 'PAT00000000000001',
          codFiscaleSpecialista: 'SPC00000000000001',
          stato: stato,
          messaggioRichiesta: messaggio,
          dataRichiesta: '2026-06-13T10:00:00Z',
          dataRisposta: dataRisposta,
          motivazioneRifiuto: motivazione,
        );

    test('maps the IT status label to the enum', () {
      expect(dto(stato: 'In Attesa').toDomain().status, LinkRequestStatus.sent);
      expect(dto(stato: 'Accettata').toDomain().status,
          LinkRequestStatus.accepted);
      expect(dto(stato: 'Rifiutata').toDomain().status,
          LinkRequestStatus.rejected);
    });

    test('parses ISO timestamps and carries through message/reason', () {
      final domain = dto(
        stato: 'Rifiutata',
        dataRisposta: '2026-06-14T09:30:00Z',
        motivazione: 'Agenda piena',
      ).toDomain();

      expect(domain.id, 42);
      expect(domain.patientTaxCode, 'PAT00000000000001');
      expect(domain.specialistTaxCode, 'SPC00000000000001');
      expect(domain.createdAt, DateTime.utc(2026, 6, 13, 10));
      expect(domain.respondedAt, DateTime.utc(2026, 6, 14, 9, 30));
      expect(domain.rejectionReason, 'Agenda piena');
      expect(domain.message, 'Ciao');
    });

    test('leaves respondedAt null when DataRisposta is absent', () {
      expect(dto().toDomain().respondedAt, isNull);
    });

    test('unknown status throws (schema drift surfaces)', () {
      expect(() => dto(stato: 'Sconosciuto').toDomain(), throwsArgumentError);
    });
  });

  group('LinkRequestWithPatientDto.fromJson + toDomain', () {
    test('reads the paziente embed into name and birth date', () {
      final json = {
        'IdRichiesta': 7,
        'CodFiscalePaziente': 'PAT00000000000002',
        'CodFiscaleSpecialista': 'SPC00000000000002',
        'Stato': 'In Attesa',
        'MessaggioRichiesta': null,
        'DataRichiesta': '2026-06-12T08:00:00Z',
        'DataRisposta': null,
        'MotivazioneRifiuto': null,
        'paziente': {
          'Nome': 'Mario',
          'Cognome': 'Rossi',
          'DataNascita': '1990-01-15',
        },
      };

      final domain = LinkRequestWithPatientDto.fromJson(json).toDomain();

      expect(domain.patientFirstName, 'Mario');
      expect(domain.patientSurname, 'Rossi');
      expect(domain.patientFullName, 'Mario Rossi');
      expect(domain.patientBirthDate, DateTime(1990, 1, 15));
      expect(domain.request.id, 7);
      expect(domain.request.status, LinkRequestStatus.sent);
      expect(domain.request.message, isNull);
    });

    test('tolerates a missing birth date in the embed', () {
      final json = {
        'IdRichiesta': 8,
        'CodFiscalePaziente': 'PAT00000000000003',
        'CodFiscaleSpecialista': 'SPC00000000000003',
        'Stato': 'In Attesa',
        'MessaggioRichiesta': 'Buongiorno',
        'DataRichiesta': '2026-06-12T08:00:00Z',
        'DataRisposta': null,
        'MotivazioneRifiuto': null,
        'paziente': {'Nome': 'Lucia', 'Cognome': 'Bianchi'},
      };

      final domain = LinkRequestWithPatientDto.fromJson(json).toDomain();
      expect(domain.patientBirthDate, isNull);
      expect(domain.request.message, 'Buongiorno');
    });
  });
}
