/// Un paziente a cui lo specialista loggato è collegato (`fascicoloclinico`
/// attivo), mostrato nella sua lista pazienti (RF18).
///
/// [fascicoloId] è l'id del fascicolo passato alle letture del diario
/// (`DiaryRepository.getMealsForDate` / `SymptomRepository.getSymptomsForDate`),
/// riusato così com'è per la vista diario in sola lettura (ADR-0016).
class LinkedPatient {
  final int fascicoloId;
  final String taxCode;
  final String firstName;
  final String surname;
  final String? email;
  final DateTime? birthDate;

  const LinkedPatient({
    required this.fascicoloId,
    required this.taxCode,
    required this.firstName,
    required this.surname,
    this.email,
    this.birthDate,
  });

  /// "Nome Cognome" per la visualizzazione.
  String get fullName => '$firstName $surname';

  /// Anni interi tra [birthDate] e [today], o `null` quando la data di nascita
  /// non è nota. Pura (niente `DateTime.now()`), quindi testabile in modo
  /// deterministico.
  int? ageAt(DateTime today) {
    final birth = birthDate;
    if (birth == null) return null;
    var age = today.year - birth.year;
    final hadBirthdayThisYear = today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!hadBirthdayThisYear) age--;
    return age < 0 ? null : age;
  }
}
