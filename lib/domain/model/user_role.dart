/// Ruoli dell'app. L'enum DB `ruolo_utente` ha anche `segretaria`, fuori scope
/// per il port dell'app paziente: è trattato come ruolo non supportato (la
/// mappatura lancia) invece di essere modellato qui.
enum UserRole {
  patient,
  specialist;

  /// Mappa un valore DB `ruolo` al ruolo di dominio.
  ///
  /// Lancia [ArgumentError] per `segretaria` o qualsiasi valore sconosciuto — il
  /// chiamante lo trasforma in un errore di dominio invece di gestirlo male in
  /// silenzio.
  static UserRole fromDb(String value) => switch (value) {
        'paziente' => UserRole.patient,
        'specialista' => UserRole.specialist,
        _ => throw ArgumentError('Unsupported role: $value'),
      };

  /// Il valore DB `ruolo` per questo ruolo (usato nei metadati di registrazione).
  String get dbValue => switch (this) {
        UserRole.patient => 'paziente',
        UserRole.specialist => 'specialista',
      };
}
