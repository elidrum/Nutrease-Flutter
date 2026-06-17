import 'symptom_severity.dart';
import 'symptom_type.dart';

/// Un sintomo del diario (riga `sintomo`).
///
/// Rispecchia esattamente il `Symptom` del port Android — niente campo `notes` a
/// testo libero: la tabella `sintomo` ha solo `Descrizione varchar(100)` (usata
/// per l'etichetta del tipo) e `Intensita`, e aggiungere una colonna note è
/// fuori scope (backend invariato). Vedi
/// `data/mapper/symptom_mapper.dart` per il motivo dietro la rinuncia alle note
/// opzionali di RF10.
class Symptom {
  final int? id;
  final int fascicoloId;
  final DateTime date;

  /// Orario come `HH:mm:ss` (colonna DB `time`).
  final String time;
  final SymptomType type;
  final SymptomSeverity severity;

  /// Etichetta a testo libero scritta in `Descrizione` quando [type] è
  /// [SymptomType.other] — ciò che lo specialista legge al posto del generico
  /// "Altro". Null/vuota per i tipi fissi.
  final String? otherDescription;

  const Symptom({
    this.id,
    required this.fascicoloId,
    required this.date,
    required this.time,
    required this.type,
    required this.severity,
    this.otherDescription,
  });
}
