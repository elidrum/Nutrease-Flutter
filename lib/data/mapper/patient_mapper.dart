import '../../domain/model/gender.dart';
import '../../domain/model/patient.dart';
import '../dto/patient_dto.dart';

/// Unico punto di traduzione tra il DTO `paziente` e il model di dominio
/// [Patient] (IT↔EN, `M/F/Altro`↔[Gender], stringa `DataNascita`↔[DateTime]).
extension PatientDtoMapper on PatientDto {
  Patient toDomain() => Patient(
        taxCode: codiceFiscale,
        firstName: nome,
        surname: cognome,
        email: email ?? '',
        birthDate: DateTime.parse(dataNascita),
        gender: Gender.fromDb(sesso),
        phone: telefono,
        city: citta,
      );
}

extension PatientToDto on Patient {
  PatientDto toDto() => PatientDto(
        codiceFiscale: taxCode,
        nome: firstName,
        cognome: surname,
        email: email,
        sesso: gender.dbValue,
        // Colonna `date` → yyyy-MM-dd (scarto la componente oraria).
        dataNascita: birthDate.toIso8601String().split('T').first,
        telefono: phone,
        citta: city,
      );
}
