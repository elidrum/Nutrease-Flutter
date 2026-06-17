import 'gender.dart';

/// Profilo paziente (tabella DB `paziente`).
///
/// Altezza/peso stanno nella tabella `misurazione` e sono fuori scope, quindi il
/// modello porta solo i campi anagrafici. [birthDate] è una data di calendario
/// (la componente oraria è ignorata).
class Patient {
  final String taxCode;
  final String firstName;
  final String surname;
  final String email;
  final DateTime birthDate;
  final Gender gender;
  final String? phone;
  final String? city;

  const Patient({
    required this.taxCode,
    required this.firstName,
    required this.surname,
    required this.email,
    required this.birthDate,
    required this.gender,
    this.phone,
    this.city,
  });

  /// Restituisce una copia con i campi anagrafici modificabili sovrascritti (RF5).
  Patient copyWith({
    String? firstName,
    String? surname,
    String? phone,
    String? city,
  }) =>
      Patient(
        taxCode: taxCode,
        firstName: firstName ?? this.firstName,
        surname: surname ?? this.surname,
        email: email,
        birthDate: birthDate,
        gender: gender,
        phone: phone ?? this.phone,
        city: city ?? this.city,
      );
}
