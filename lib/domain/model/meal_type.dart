/// Tipo di pasto, che rispecchia l'enum DB `tipologia_pasto`.
///
/// Le etichette DB sono `Colazione/Pranzo/Merenda/Cena` — è "Merenda", non
/// "Spuntino" (il backend è intoccabile).
enum MealType {
  breakfast('Colazione'),
  lunch('Pranzo'),
  snack('Merenda'),
  dinner('Cena');

  /// Etichetta dell'enum DB; è anche l'etichetta UI in italiano.
  final String dbValue;

  const MealType(this.dbValue);

  static MealType fromDb(String value) =>
      values.firstWhere(
        (type) => type.dbValue == value,
        orElse: () =>
            throw ArgumentError('Tipologia pasto sconosciuta: $value'),
      );
}
