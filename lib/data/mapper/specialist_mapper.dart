import '../../domain/model/specialist.dart';
import '../../domain/model/specialization_type.dart';
import '../dto/specialist_dto.dart';

/// Unico punto di traduzione tra il DTO `specialista` e il model di dominio
/// [Specialist] (IT↔EN, `Nutrizionista/...`↔[SpecializationType]).
extension SpecialistDtoMapper on SpecialistDto {
  Specialist toDomain() => Specialist(
        taxCode: codiceFiscale,
        firstName: nome,
        surname: cognome,
        email: email ?? '',
        vatNumber: partitaIva,
        specialization: SpecializationType.fromDbLabel(specializzazione),
        city: citta,
        info: info,
      );
}

extension SpecialistToDto on Specialist {
  SpecialistDto toDto() => SpecialistDto(
        codiceFiscale: taxCode,
        nome: firstName,
        cognome: surname,
        email: email,
        partitaIva: vatNumber,
        specializzazione: specialization?.dbLabel,
        citta: city,
        info: info,
      );
}
