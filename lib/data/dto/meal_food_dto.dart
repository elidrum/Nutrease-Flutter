import 'food_dto.dart';

/// DTO della riga `alimento_pasto`.
///
/// Le colonne `*Calc` sono read-only: le popola il trigger
/// `calcola_nutrienti_pasto`, quindi [toInsertJson] non le invia mai (ADR-0010).
class MealFoodDto {
  final int? idAlimentoPasto;
  final int? idPasto;
  final int idAlimento;
  final num quantitaGrammi;
  final String? unitaMisuraOrig;
  final num? quantitaOrig;
  final num lattosioCalc;
  final num sorbitoloCalc;
  final num glutineCalc;
  final num calorieCalc;

  /// Riga `alimento` embeddata (PostgREST `alimento(...)`), solo in lettura.
  final FoodDto? alimento;

  const MealFoodDto({
    this.idAlimentoPasto,
    this.idPasto,
    required this.idAlimento,
    required this.quantitaGrammi,
    this.unitaMisuraOrig,
    this.quantitaOrig,
    this.lattosioCalc = 0,
    this.sorbitoloCalc = 0,
    this.glutineCalc = 0,
    this.calorieCalc = 0,
    this.alimento,
  });

  factory MealFoodDto.fromJson(Map<String, dynamic> json) => MealFoodDto(
        idAlimentoPasto: json['IdAlimentoPasto'] as int?,
        idPasto: json['IdPasto'] as int?,
        idAlimento: json['IdAlimento'] as int,
        quantitaGrammi: FoodDto.asNum(json['QuantitaGrammi']),
        unitaMisuraOrig: json['UnitaMisuraOrig'] as String?,
        quantitaOrig: json['QuantitaOrig'] == null
            ? null
            : FoodDto.asNum(json['QuantitaOrig']),
        lattosioCalc: FoodDto.asNum(json['LattosioCalc']),
        sorbitoloCalc: FoodDto.asNum(json['SorbitoloCalc']),
        glutineCalc: FoodDto.asNum(json['GlutineCalc']),
        calorieCalc: FoodDto.asNum(json['CalorieCalc']),
        alimento: json['alimento'] == null
            ? null
            : FoodDto.fromJson(json['alimento'] as Map<String, dynamic>),
      );

  /// Payload di scrittura: solo quantità grezze, mai le colonne `*Calc`.
  Map<String, dynamic> toInsertJson(int mealId) => {
        'IdPasto': mealId,
        'IdAlimento': idAlimento,
        'QuantitaGrammi': quantitaGrammi,
        'UnitaMisuraOrig': unitaMisuraOrig,
        'QuantitaOrig': quantitaOrig,
      };
}
