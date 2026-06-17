/// Proiezione minima di `fascicoloclinico`: solo l'id del fascicolo attivo.
class FascicoloIdDto {
  final int idFascicolo;

  const FascicoloIdDto({required this.idFascicolo});

  factory FascicoloIdDto.fromJson(Map<String, dynamic> json) =>
      FascicoloIdDto(idFascicolo: json['IdFascicolo'] as int);
}
