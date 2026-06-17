/// Categoria professionale dello specialista. Mappa l'enum DB
/// `tipo_specializ_enum`.
///
/// Usata anche come filtro nella ricerca specialisti (RF13).
enum SpecializationType {
  nutritionist('Nutrizionista'),
  dietitian('Dietista'),
  gastroenterologist('Gastroenterologo');

  const SpecializationType(this.dbLabel);

  /// L'etichetta esatta dell'enum DB, inviata/letta alla lettera.
  final String dbLabel;

  /// Rimappa un'etichetta DB all'enum, o `null` se assente/sconosciuta.
  static SpecializationType? fromDbLabel(String? label) {
    if (label == null) return null;
    for (final value in SpecializationType.values) {
      if (value.dbLabel == label) return value;
    }
    return null;
  }
}
