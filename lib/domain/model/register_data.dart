import 'gender.dart';
import 'specialization_type.dart';

/// Input di registrazione. [toAuthMetadata] produce **esattamente** le chiavi
/// lette dal trigger `crea_profilo_da_auth` (ADR-0015): il client non inserisce
/// mai direttamente in `paziente`/`specialista` — il trigger fa 3 INSERT atomici
/// al `signUp`, così un fallimento fa rollback dell'utente auth (nessun account
/// in limbo).
sealed class RegisterData {
  final String email;
  final String password;
  final String firstName;
  final String surname;
  final String taxCode;

  const RegisterData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.surname,
    required this.taxCode,
  });

  /// La mappa `raw_user_meta_data` inviata in `signUp(..., data:)`.
  Map<String, String> toAuthMetadata();

  Map<String, String> _commonMetadata() => {
        'codice_fiscale': taxCode,
        'nome': firstName,
        'cognome': surname,
      };
}

class PatientRegisterData extends RegisterData {
  final Gender gender;
  final DateTime birthDate;

  const PatientRegisterData({
    required super.email,
    required super.password,
    required super.firstName,
    required super.surname,
    required super.taxCode,
    required this.gender,
    required this.birthDate,
  });

  @override
  Map<String, String> toAuthMetadata() => {
        ..._commonMetadata(),
        'ruolo': 'paziente',
        'sesso': gender.dbValue,
        // colonna `date` → yyyy-MM-dd (si scarta la componente oraria).
        'data_nascita': birthDate.toIso8601String().split('T').first,
      };
}

class SpecialistRegisterData extends RegisterData {
  final String vatNumber;
  final SpecializationType specialization;
  final String city;

  const SpecialistRegisterData({
    required super.email,
    required super.password,
    required super.firstName,
    required super.surname,
    required super.taxCode,
    required this.vatNumber,
    required this.specialization,
    required this.city,
  });

  @override
  Map<String, String> toAuthMetadata() => {
        ..._commonMetadata(),
        'ruolo': 'specialista',
        'partita_iva': vatNumber,
        'specializzazione': specialization.dbLabel,
        'citta': city,
      };
}
