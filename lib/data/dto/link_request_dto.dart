/// DTO di una riga `richiesta_collegamento` (identificatori PascalCase quotati).
class LinkRequestDto {
  final int idRichiesta;
  final String codFiscalePaziente;
  final String codFiscaleSpecialista;
  final String stato;
  final String? messaggioRichiesta;
  final String dataRichiesta;
  final String? dataRisposta;
  final String? motivazioneRifiuto;

  const LinkRequestDto({
    required this.idRichiesta,
    required this.codFiscalePaziente,
    required this.codFiscaleSpecialista,
    required this.stato,
    required this.messaggioRichiesta,
    required this.dataRichiesta,
    required this.dataRisposta,
    required this.motivazioneRifiuto,
  });

  factory LinkRequestDto.fromJson(Map<String, dynamic> json) => LinkRequestDto(
        idRichiesta: json['IdRichiesta'] as int,
        codFiscalePaziente: json['CodFiscalePaziente'] as String,
        codFiscaleSpecialista: json['CodFiscaleSpecialista'] as String,
        stato: json['Stato'] as String,
        messaggioRichiesta: json['MessaggioRichiesta'] as String?,
        dataRichiesta: json['DataRichiesta'] as String,
        dataRisposta: json['DataRisposta'] as String?,
        motivazioneRifiuto: json['MotivazioneRifiuto'] as String?,
      );
}

/// `richiesta_collegamento` unita all'embed `paziente(Nome,Cognome,DataNascita)`,
/// per la inbox dello specialista (RF15).
class LinkRequestWithPatientDto {
  final LinkRequestDto request;
  final String pazienteNome;
  final String pazienteCognome;
  final String? pazienteDataNascita;

  const LinkRequestWithPatientDto({
    required this.request,
    required this.pazienteNome,
    required this.pazienteCognome,
    required this.pazienteDataNascita,
  });

  factory LinkRequestWithPatientDto.fromJson(Map<String, dynamic> json) {
    final paziente = json['paziente'] as Map<String, dynamic>?;
    return LinkRequestWithPatientDto(
      request: LinkRequestDto.fromJson(json),
      pazienteNome: paziente?['Nome'] as String? ?? '',
      pazienteCognome: paziente?['Cognome'] as String? ?? '',
      pazienteDataNascita: paziente?['DataNascita'] as String?,
    );
  }
}
