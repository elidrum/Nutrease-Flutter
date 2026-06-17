import '../../domain/model/symptom.dart';
import '../../domain/model/symptom_severity.dart';
import '../../domain/model/symptom_type.dart';
import '../dto/symptom_dto.dart';

/// Unico punto di traduzione tra `sintomo` e il dominio [Symptom] (IT↔EN,
/// `Intensita`↔[SymptomSeverity], parsing di `Data`/`Ora`).
///
/// **Le note non vengono persistite, di proposito.** RF10 cita note testuali
/// opzionali, ma `sintomo` non ha una colonna dedicata: `Descrizione
/// varchar(100)` porta l'etichetta del tipo, e l'app specialista Android la
/// rilegge per match *esatto* di stringa (`"Gonfiore" → BLOATING`, altrimenti
/// `OTHER`). Accodare una nota a `Descrizione` farebbe leggere male il tipo ad
/// Android, e aggiungere una colonna è fuori scope (backend invariato). La
/// specifica consente esplicitamente di omettere le note quando non c'è
/// una colonna, quindi [Symptom] lascia cadere il campo — 1:1 col porting
/// Android.
///
/// Le etichette di tipo usano le stesse stringhe capitalizzate che scrive l'app
/// Android, così i dati sono compatibili in entrambe le direzioni; le letture
/// sono case-insensitive per robustezza.

extension SymptomToDto on Symptom {
  SymptomDto toDto() => SymptomDto(
        idSintomo: id,
        idFascicolo: fascicoloId,
        // Colonna `date` → yyyy-MM-dd (scarto la componente oraria).
        data: date.toIso8601String().split('T').first,
        ora: time,
        descrizione: _descriptionFor(this),
        intensita: SymptomSeverity.toIntensity(severity),
      );
}

Symptom symptomFromDto(SymptomDto dto) {
  final type = _descriptionToType(dto.descrizione);
  return Symptom(
    id: dto.idSintomo,
    fascicoloId: dto.idFascicolo,
    date: DateTime.parse(dto.data),
    time: _normalizeTime(dto.ora),
    type: type,
    severity: SymptomSeverity.fromIntensity(dto.intensita),
    // Per "altro", la Descrizione grezza è l'etichetta testuale del paziente.
    otherDescription:
        type == SymptomType.other ? dto.descrizione.trim() : null,
  );
}

/// `Descrizione` da scrivere: l'etichetta testuale per [SymptomType.other] (così
/// la vede lo specialista), altrimenti l'etichetta di tipo fissa e capitalizzata.
String _descriptionFor(Symptom symptom) {
  if (symptom.type == SymptomType.other) {
    final custom = symptom.otherDescription?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
  }
  return _typeToDescription(symptom.type);
}

/// Tipo di dominio → `Descrizione` (italiano capitalizzato, come il porting Android).
String _typeToDescription(SymptomType type) => switch (type) {
      SymptomType.bloating => 'Gonfiore',
      SymptomType.cramps => 'Crampi',
      SymptomType.diarrhea => 'Diarrea',
      SymptomType.constipation => 'Stitichezza',
      SymptomType.nausea => 'Nausea',
      SymptomType.reflux => 'Reflusso',
      SymptomType.other => 'Altro',
    };

/// `Descrizione` → tipo di dominio; case-insensitive, etichette ignote → [SymptomType.other].
SymptomType _descriptionToType(String description) =>
    switch (description.trim().toLowerCase()) {
      'gonfiore' => SymptomType.bloating,
      'crampi' => SymptomType.cramps,
      'diarrea' => SymptomType.diarrhea,
      'stitichezza' => SymptomType.constipation,
      'nausea' => SymptomType.nausea,
      'reflusso' => SymptomType.reflux,
      _ => SymptomType.other,
    };

/// Le colonne `time` possono rileggersi come `HH:mm:ss.ffffff`; tengo `HH:mm:ss`.
String _normalizeTime(String raw) => raw.split('.').first;
