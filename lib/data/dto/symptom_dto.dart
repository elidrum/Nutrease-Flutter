/// DTO della riga `sintomo`.
///
/// Colonne: `IdSintomo` (bigserial), `IdFascicolo`, `Data` (date), `Ora` (time),
/// `Descrizione` (varchar 100, contiene l'etichetta italiana del tipo) e
/// `Intensita` (smallint 1–10). Non c'è una colonna note — vedi
/// `symptom_mapper.dart`.
class SymptomDto {
  final int? idSintomo;
  final int idFascicolo;

  /// `yyyy-MM-dd`.
  final String data;

  /// `HH:mm:ss` (in lettura il DB può accodare i microsecondi).
  final String ora;

  /// Etichetta italiana del tipo di sintomo (es. `Gonfiore`).
  final String descrizione;
  final int intensita;

  const SymptomDto({
    this.idSintomo,
    required this.idFascicolo,
    required this.data,
    required this.ora,
    required this.descrizione,
    required this.intensita,
  });

  factory SymptomDto.fromJson(Map<String, dynamic> json) => SymptomDto(
        idSintomo: json['IdSintomo'] as int?,
        idFascicolo: json['IdFascicolo'] as int,
        data: json['Data'] as String,
        ora: json['Ora'] as String,
        descrizione: json['Descrizione'] as String,
        intensita: (json['Intensita'] as num).toInt(),
      );

  /// Payload di insert/update: `IdSintomo` omesso (lo assegna il bigserial).
  Map<String, dynamic> toJson() => {
        'IdFascicolo': idFascicolo,
        'Data': data,
        'Ora': ora,
        'Descrizione': descrizione,
        'Intensita': intensita,
      };
}
