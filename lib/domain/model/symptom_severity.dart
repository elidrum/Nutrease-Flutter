/// Fascia di severità di un sintomo (RF10).
///
/// Due conversioni pure e testabili sulla colonna `sintomo.Intensita` (1–10):
/// * [toIntensity] — ciò che **scriviamo**: i valori canonici `1/3/6/9`.
/// * [fromIntensity] — ciò che **leggiamo**: un valore 1–10 qualsiasi raggruppato
///   nei quattro livelli alle soglie `2 / 4 / 7`.
///
/// Le fasce coincidono 1:1 col port Android (`2 / 4 / 7`), così i dati scritti da
/// uno dei due client si rileggono allo stesso livello.
enum SymptomSeverity {
  none,
  mild,
  moderate,
  severe;

  /// Raggruppamento in lettura della `Intensita` DB (1–10) in quattro livelli.
  static SymptomSeverity fromIntensity(int i) {
    if (i <= 2) return SymptomSeverity.none;
    if (i <= 4) return SymptomSeverity.mild;
    if (i <= 7) return SymptomSeverity.moderate;
    return SymptomSeverity.severe;
  }

  /// `Intensita` canonica in scrittura per questo livello.
  static int toIntensity(SymptomSeverity s) => switch (s) {
        SymptomSeverity.none => 1,
        SymptomSeverity.mild => 3,
        SymptomSeverity.moderate => 6,
        SymptomSeverity.severe => 9,
      };
}
