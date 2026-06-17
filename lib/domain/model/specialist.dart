import 'specialization_type.dart';

/// Profilo specialista (tabella DB `specialista`).
class Specialist {
  final String taxCode;
  final String firstName;
  final String surname;
  final String email;
  final String vatNumber;
  final SpecializationType? specialization;
  final String? city;
  final String? info;

  const Specialist({
    required this.taxCode,
    required this.firstName,
    required this.surname,
    required this.email,
    required this.vatNumber,
    this.specialization,
    this.city,
    this.info,
  });

  /// Restituisce una copia con i campi professionali modificabili sovrascritti (RF5).
  Specialist copyWith({
    String? firstName,
    String? surname,
    String? vatNumber,
    SpecializationType? specialization,
    String? city,
    String? info,
  }) =>
      Specialist(
        taxCode: taxCode,
        firstName: firstName ?? this.firstName,
        surname: surname ?? this.surname,
        email: email,
        vatNumber: vatNumber ?? this.vatNumber,
        specialization: specialization ?? this.specialization,
        city: city ?? this.city,
        info: info ?? this.info,
      );
}
