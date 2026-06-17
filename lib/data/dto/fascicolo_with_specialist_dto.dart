import 'specialist_dto.dart';

/// Proiezione di `fascicoloclinico` con lo specialista titolare embeddato.
///
/// [specialist] è **nullable**: quando le RLS filtrano via la riga embeddata (es.
/// uno specialista de-verificato dopo il collegamento, ADR-0028), PostgREST invia
/// `"specialista": null` — da trattare come "nessuno specialista visibile", non
/// come errore di decodifica. (L'[FascicoloIdDto] solo-id resta per la sua
/// proiezione.)
class FascicoloWithSpecialistDto {
  final int idFascicolo;
  final SpecialistDto? specialist;

  const FascicoloWithSpecialistDto({
    required this.idFascicolo,
    required this.specialist,
  });

  factory FascicoloWithSpecialistDto.fromJson(Map<String, dynamic> json) {
    final embed = json['specialista'] as Map<String, dynamic>?;
    return FascicoloWithSpecialistDto(
      idFascicolo: json['IdFascicolo'] as int,
      specialist: embed == null ? null : SpecialistDto.fromJson(embed),
    );
  }
}
