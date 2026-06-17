/// Categoria di sintomo, che rispecchia il `SymptomType` del port Android (RF10).
///
/// Enum di dominio in inglese puro: l'etichetta DB italiana e quella UI italiana
/// stanno rispettivamente nel mapper (`sintomo.Descrizione`) e in `core/strings`,
/// mai qui (il dominio resta neutro rispetto alla lingua, ADR-0007 / regole del
/// glossario).
enum SymptomType {
  bloating,
  cramps,
  diarrhea,
  constipation,
  nausea,
  reflux,
  other,
}
