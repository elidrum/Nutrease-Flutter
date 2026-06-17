/// Sesso del paziente. Mappa l'enum DB `sesso_paziente` (`M` / `F` / `Altro`).
enum Gender {
  male,
  female,
  other;

  /// Mappa un valore DB `Sesso`; tutto ciò che non è `M`/`F` ricade su [other].
  static Gender fromDb(String value) => switch (value) {
        'M' => Gender.male,
        'F' => Gender.female,
        _ => Gender.other,
      };

  /// Il valore DB `Sesso` per questo genere.
  String get dbValue => switch (this) {
        Gender.male => 'M',
        Gender.female => 'F',
        Gender.other => 'Altro',
      };
}
