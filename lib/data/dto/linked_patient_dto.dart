/// DTO di una riga `fascicoloclinico` con l'embed `paziente(...)`, per elencare i
/// pazienti collegati di uno specialista (RF18). Gli identificatori DB sono
/// PascalCase quotati.
///
/// I campi dell'embed paziente sono nullable per difesa: se le RLS filtrassero la
/// riga embeddata, PostgREST invierebbe `"paziente": null` e il mapper scarta la
/// riga invece di sollevare.
class LinkedPatientDto {
  final int idFascicolo;
  final String stato;
  final String? pazienteCodiceFiscale;
  final String? pazienteNome;
  final String? pazienteCognome;
  final String? pazienteEmail;
  final String? pazienteDataNascita;

  const LinkedPatientDto({
    required this.idFascicolo,
    required this.stato,
    required this.pazienteCodiceFiscale,
    required this.pazienteNome,
    required this.pazienteCognome,
    required this.pazienteEmail,
    required this.pazienteDataNascita,
  });

  factory LinkedPatientDto.fromJson(Map<String, dynamic> json) {
    final paziente = json['paziente'] as Map<String, dynamic>?;
    return LinkedPatientDto(
      idFascicolo: json['IdFascicolo'] as int,
      stato: json['Stato'] as String,
      pazienteCodiceFiscale: paziente?['CodiceFiscale'] as String?,
      pazienteNome: paziente?['Nome'] as String?,
      pazienteCognome: paziente?['Cognome'] as String?,
      pazienteEmail: paziente?['Email'] as String?,
      pazienteDataNascita: paziente?['DataNascita'] as String?,
    );
  }
}
