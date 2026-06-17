/// DTO della riga `pasto`.
class MealDto {
  final int? idPasto;
  final int idFascicolo;

  /// `yyyy-MM-dd`.
  final String data;

  /// `HH:mm:ss` (in lettura il DB può accodare i microsecondi).
  final String ora;

  /// Etichetta `tipologia_pasto` (Colazione/Pranzo/Merenda/Cena).
  final String tipologia;
  final String? descrizione;

  const MealDto({
    this.idPasto,
    required this.idFascicolo,
    required this.data,
    required this.ora,
    required this.tipologia,
    this.descrizione,
  });

  factory MealDto.fromJson(Map<String, dynamic> json) => MealDto(
        idPasto: json['IdPasto'] as int?,
        idFascicolo: json['IdFascicolo'] as int,
        data: json['Data'] as String,
        ora: json['Ora'] as String,
        tipologia: json['Tipologia'] as String,
        descrizione: json['Descrizione'] as String?,
      );

  /// Payload di insert/update: `IdPasto` omesso (lo assegna il bigserial).
  Map<String, dynamic> toJson() => {
        'IdFascicolo': idFascicolo,
        'Data': data,
        'Ora': ora,
        'Tipologia': tipologia,
        if (descrizione != null) 'Descrizione': descrizione,
      };
}
