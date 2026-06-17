/// DTO della riga `paziente`. Il DB usa identificatori PascalCase quotati, quindi
/// le chiavi JSON corrispondono a quei nomi alla lettera.
class PatientDto {
  final String codiceFiscale;
  final String nome;
  final String cognome;
  final String? email;
  final String sesso;
  final String dataNascita;
  final String? telefono;
  final String? citta;

  const PatientDto({
    required this.codiceFiscale,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.sesso,
    required this.dataNascita,
    required this.telefono,
    required this.citta,
  });

  factory PatientDto.fromJson(Map<String, dynamic> json) => PatientDto(
        codiceFiscale: json['CodiceFiscale'] as String,
        nome: json['Nome'] as String,
        cognome: json['Cognome'] as String,
        email: json['Email'] as String?,
        sesso: json['Sesso'] as String,
        dataNascita: json['DataNascita'] as String,
        telefono: json['Telefono'] as String?,
        citta: json['Citta'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'CodiceFiscale': codiceFiscale,
        'Nome': nome,
        'Cognome': cognome,
        'Email': email,
        'Sesso': sesso,
        'DataNascita': dataNascita,
        'Telefono': telefono,
        'Citta': citta,
      };
}
