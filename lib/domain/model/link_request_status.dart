/// Stato di una riga `richiesta_collegamento`. Mappa l'enum DB `stato_richiesta`
/// (`In Attesa` / `Accettata` / `Rifiutata`).
enum LinkRequestStatus {
  sent('In Attesa'),
  accepted('Accettata'),
  rejected('Rifiutata');

  const LinkRequestStatus(this.dbLabel);

  /// L'etichetta esatta dell'enum DB, inviata/letta alla lettera.
  final String dbLabel;

  /// Rimappa un'etichetta DB all'enum. Lancia su un valore sconosciuto così un
  /// drift di schema emerge invece di essere gestito male in silenzio.
  static LinkRequestStatus fromDbLabel(String label) {
    for (final value in LinkRequestStatus.values) {
      if (value.dbLabel == label) return value;
    }
    throw ArgumentError('Unknown link request status: $label');
  }
}
