/// Regola sulla data di nascita per la registrazione paziente (RF2 / ADR-0026):
/// la data dev'essere nel passato e la persona deve avere almeno [minAge] anni.
///
/// Pura e senza framework; [now] è iniettabile per rendere i test deterministici.
/// Rispecchia il port Android (`AgePolicy.MIN_AGE_YEARS = 18`).
abstract final class AgePolicy {
  static const int minAge = 18;

  /// Vero se [birthDate] è una data di registrazione valida: nel passato e con
  /// età ≥ [minAge].
  static bool isValidBirthDate(DateTime birthDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    if (!birthDate.isBefore(today)) return false;
    return _ageOn(birthDate, today) >= minAge;
  }

  /// Anni compiuti tra [birthDate] e [on].
  static int _ageOn(DateTime birthDate, DateTime on) {
    var age = on.year - birthDate.year;
    final hadBirthday = on.month > birthDate.month ||
        (on.month == birthDate.month && on.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age;
  }
}
