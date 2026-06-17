/// DTO della riga `specialista` (identificatori PascalCase quotati nel DB).
class SpecialistDto {
  final String codiceFiscale;
  final String nome;
  final String cognome;
  final String? email;
  final String partitaIva;
  final String? specializzazione;
  final String? citta;
  final String? info;

  const SpecialistDto({
    required this.codiceFiscale,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.partitaIva,
    required this.specializzazione,
    required this.citta,
    required this.info,
  });

  factory SpecialistDto.fromJson(Map<String, dynamic> json) => SpecialistDto(
        codiceFiscale: json['CodiceFiscale'] as String,
        nome: json['Nome'] as String,
        cognome: json['Cognome'] as String,
        email: json['Email'] as String?,
        partitaIva: json['PartitaIVA'] as String,
        specializzazione: json['Specializzazione'] as String?,
        citta: json['Citta'] as String?,
        info: json['Info'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'CodiceFiscale': codiceFiscale,
        'Nome': nome,
        'Cognome': cognome,
        'Email': email,
        'PartitaIVA': partitaIva,
        'Specializzazione': specializzazione,
        'Citta': citta,
        'Info': info,
      };
}
