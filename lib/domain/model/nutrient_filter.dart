/// Selettore di evidenziazione nutriente per la vista diario dello specialista
/// (RF20).
///
/// Solo **evidenziazione**, mai un filtro vero: il nutriente scelto viene messo
/// in risalto nelle card e nell'aggregato per-giorno, ma la lista delle voci non
/// viene mai tagliata. [all] significa "nessun
/// risalto specifico".
enum NutrientFilter { all, lactose, sorbitol, gluten, kcal }
