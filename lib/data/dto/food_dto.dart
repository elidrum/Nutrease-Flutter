/// DTO della riga `alimento`. Le chiavi JSON corrispondono ai nomi colonna in
/// PascalCase quotato. `Alias`/`FonteDati` e le colonne macro extra non sono
/// usate dal client MVP.
class FoodDto {
  final int idAlimento;
  final String nome;
  final String? categoria;
  final num lattosioP100g;
  final num sorbitoloP100g;
  final num glutineP100g;
  final num caloriePer100g;

  /// Jsonb `ConversioniUnitaMisura` grezzo; i valori possono arrivare come int o double.
  final Map<String, dynamic> conversioniUnitaMisura;

  const FoodDto({
    required this.idAlimento,
    required this.nome,
    this.categoria,
    this.lattosioP100g = 0,
    this.sorbitoloP100g = 0,
    this.glutineP100g = 0,
    this.caloriePer100g = 0,
    this.conversioniUnitaMisura = const {},
  });

  factory FoodDto.fromJson(Map<String, dynamic> json) => FoodDto(
        idAlimento: json['IdAlimento'] as int,
        nome: json['Nome'] as String,
        categoria: json['Categoria'] as String?,
        lattosioP100g: asNum(json['LattosioP100g']),
        sorbitoloP100g: asNum(json['SorbitoloP100g']),
        glutineP100g: asNum(json['GlutineP100g']),
        caloriePer100g: asNum(json['CaloriePer100g']),
        conversioniUnitaMisura:
            (json['ConversioniUnitaMisura'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'IdAlimento': idAlimento,
        'Nome': nome,
        'Categoria': categoria,
        'LattosioP100g': lattosioP100g,
        'SorbitoloP100g': sorbitoloP100g,
        'GlutineP100g': glutineP100g,
        'CaloriePer100g': caloriePer100g,
        'ConversioniUnitaMisura': conversioniUnitaMisura,
      };

  /// Le colonne `numeric` possono decodificare come int, double o stringa a
  /// seconda del driver; normalizzo a [num]. Condivisa con gli altri DTO del diario.
  static num asNum(dynamic value) => switch (value) {
        null => 0,
        final num n => n,
        final String s => num.tryParse(s) ?? 0,
        _ => 0,
      };
}
