import '../../domain/model/food.dart';
import '../../domain/model/meal.dart';
import '../../domain/model/meal_food_item.dart';
import '../../domain/model/meal_type.dart';
import '../../domain/model/nutrient_totals.dart';
import '../dto/meal_dto.dart';
import '../dto/meal_food_dto.dart';
import 'food_mapper.dart';

/// Unico punto di traduzione tra `pasto`/`alimento_pasto` e il dominio [Meal]
/// (IT↔EN, `Tipologia`↔[MealType], parsing di `Data`/`Ora`).

extension MealToDto on Meal {
  MealDto toDto() => MealDto(
        idPasto: id,
        idFascicolo: fascicoloId,
        // Colonna `date` → yyyy-MM-dd (scarto la componente oraria).
        data: date.toIso8601String().split('T').first,
        ora: time,
        tipologia: type.dbValue,
      );
}

extension MealFoodItemToDto on MealFoodItem {
  /// Solo quantità grezze: le colonne `*Calc` le calcola il trigger.
  MealFoodDto toDto() => MealFoodDto(
        idAlimento: food.id,
        quantitaGrammi: amountGrams,
        unitaMisuraOrig: unit,
        quantitaOrig: amount,
      );
}

/// Costruisce il dominio [Meal] dalla riga `pasto` e dalle sue righe
/// `alimento_pasto`; [totals] è la somma delle colonne `*Calc` calcolate dal
/// trigger.
Meal mealFromDto(MealDto dto, List<MealFoodDto> items) {
  var totals = NutrientTotals.zero;
  for (final item in items) {
    totals = totals +
        NutrientTotals(
          lactose: item.lattosioCalc.toDouble(),
          sorbitol: item.sorbitoloCalc.toDouble(),
          gluten: item.glutineCalc.toDouble(),
          kcal: item.calorieCalc.toDouble(),
        );
  }
  return Meal(
    id: dto.idPasto,
    fascicoloId: dto.idFascicolo,
    date: DateTime.parse(dto.data),
    time: normalizeDbTime(dto.ora),
    type: MealType.fromDb(dto.tipologia),
    items: items.map(mealFoodItemFromDto).toList(),
    totals: totals,
  );
}

/// Ricostruisce il [MealFoodItem] esposto alla UI da una riga di dettaglio.
///
/// Usa l'`alimento` embeddato quando c'è; se l'unità salvata non è più tra le
/// conversioni dell'alimento (o l'embed manca), ricava il fattore da
/// grammi/originale così `amountGrams` resta coerente con la riga del DB.
MealFoodItem mealFoodItemFromDto(MealFoodDto dto) {
  final unit = dto.unitaMisuraOrig ?? Food.unitGrams;
  final amount = (dto.quantitaOrig ?? dto.quantitaGrammi).toDouble();

  var food = dto.alimento?.toDomain() ??
      Food(id: dto.idAlimento, name: 'Alimento sconosciuto');

  final needsDerivedFactor =
      unit != Food.unitGrams && !food.unitConversions.containsKey(unit);
  if (needsDerivedFactor && amount > 0) {
    food = Food(
      id: food.id,
      name: food.name,
      category: food.category,
      lactosePer100g: food.lactosePer100g,
      sorbitolPer100g: food.sorbitolPer100g,
      glutenPer100g: food.glutenPer100g,
      kcalPer100g: food.kcalPer100g,
      unitConversions: {
        ...food.unitConversions,
        unit: dto.quantitaGrammi.toDouble() / amount,
      },
    );
  }

  return MealFoodItem(food: food, amount: amount, unit: unit);
}

/// Le colonne `time` possono rileggersi come `HH:mm:ss.ffffff`; tengo `HH:mm:ss`.
String normalizeDbTime(String raw) => raw.split('.').first;
