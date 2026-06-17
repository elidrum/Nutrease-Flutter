/// DTO della riga `profilo_utente` (colonne snake_case, come nel DB).
class UserProfileDto {
  final String authUid;
  final String ruolo;
  final String codiceFiscale;

  const UserProfileDto({
    required this.authUid,
    required this.ruolo,
    required this.codiceFiscale,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => UserProfileDto(
        authUid: json['auth_uid'] as String,
        ruolo: json['ruolo'] as String,
        codiceFiscale: json['codice_fiscale'] as String,
      );

  Map<String, dynamic> toJson() => {
        'auth_uid': authUid,
        'ruolo': ruolo,
        'codice_fiscale': codiceFiscale,
      };
}
