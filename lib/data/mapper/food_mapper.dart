import '../../domain/model/food.dart';
import '../dto/food_dto.dart';

/// Unico punto di traduzione tra il DTO `alimento` e il model di dominio [Food]
/// (IT→EN, conversioni jsonb → `Map<String,double>`).
extension FoodDtoMapper on FoodDto {
  Food toDomain() => Food(
        id: idAlimento,
        name: nome,
        category: categoria,
        lactosePer100g: lattosioP100g.toDouble(),
        sorbitolPer100g: sorbitoloP100g.toDouble(),
        glutenPer100g: glutineP100g.toDouble(),
        kcalPer100g: caloriePer100g.toDouble(),
        unitConversions: parseUnitConversions(conversioniUnitaMisura),
      );
}

/// Parsa il jsonb `ConversioniUnitaMisura` in fattori grammi-per-unità. I valori
/// possono arrivare come int o double; le voci non numeriche vengono scartate.
Map<String, double> parseUnitConversions(Map<String, dynamic> raw) {
  final result = <String, double>{};
  for (final MapEntry(:key, :value) in raw.entries) {
    final factor = switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };
    if (factor != null) result[key] = factor;
  }
  return result;
}
