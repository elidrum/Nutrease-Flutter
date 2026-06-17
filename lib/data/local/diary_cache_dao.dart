import 'package:sqflite/sqflite.dart';

import '../../domain/model/meal.dart';
import '../../domain/model/meal_type.dart';
import '../../domain/model/nutrient_totals.dart';
import '../../domain/model/symptom.dart';
import '../../domain/model/symptom_severity.dart';
import '../../domain/model/symptom_type.dart';
import 'diary_cache_db.dart';

/// DAO sulla cache del diario `sqflite` (lettura offline parziale RF11).
///
/// Il database si apre lazy al primo uso (la DI costruisce il DAO in modo
/// sincrono). I test iniettano un opener diverso (es. un database FFI in memoria).
/// Ogni `update`/`delete` usa `where`/`whereArgs` — mai concatenazione di stringhe
/// — per prevenire SQL injection.
class DiaryCacheDao {
  final Future<Database> Function() _open;
  Future<Database>? _dbFuture;

  DiaryCacheDao({Future<Database> Function()? open})
      : _open = open ?? openDiaryCacheDb;

  Future<Database> get _db => _dbFuture ??= _open();

  static String _dateKey(DateTime date) =>
      date.toIso8601String().split('T').first;

  /// Sostituisce in cache pasti **e** sintomi di [date]/[fascicoloId].
  Future<void> upsertDay(
    int fascicoloId,
    DateTime date,
    List<Meal> meals,
    List<Symptom> symptoms,
  ) async {
    await replaceMeals(fascicoloId, date, meals);
    await replaceSymptoms(fascicoloId, date, symptoms);
  }

  /// Sostituisce in cache solo i pasti del giorno (delete-then-insert), lasciando
  /// intatte le righe sintomo così i due percorsi cache-aside non si pestano i
  /// piedi.
  Future<void> replaceMeals(
      int fascicoloId, DateTime date, List<Meal> meals) async {
    final db = await _db;
    final dateKey = _dateKey(date);
    await db.transaction((txn) async {
      await txn.delete(
        cachedMealTable,
        where: '${CacheColumns.fascicoloId} = ? AND ${CacheColumns.date} = ?',
        whereArgs: [fascicoloId, dateKey],
      );
      for (final meal in meals) {
        if (meal.id == null) continue;
        await txn.insert(
          cachedMealTable,
          _mealToMap(meal, fascicoloId, dateKey),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _markDaySynced(txn, fascicoloId, dateKey);
    });
  }

  Future<void> replaceSymptoms(
      int fascicoloId, DateTime date, List<Symptom> symptoms) async {
    final db = await _db;
    final dateKey = _dateKey(date);
    await db.transaction((txn) async {
      await txn.delete(
        cachedSymptomTable,
        where: '${CacheColumns.fascicoloId} = ? AND ${CacheColumns.date} = ?',
        whereArgs: [fascicoloId, dateKey],
      );
      for (final symptom in symptoms) {
        if (symptom.id == null) continue;
        await txn.insert(
          cachedSymptomTable,
          _symptomToMap(symptom, fascicoloId, dateKey),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _markDaySynced(txn, fascicoloId, dateKey);
    });
  }

  Future<List<Meal>> getMeals(int fascicoloId, DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      cachedMealTable,
      where: '${CacheColumns.fascicoloId} = ? AND ${CacheColumns.date} = ?',
      whereArgs: [fascicoloId, _dateKey(date)],
      orderBy: '${CacheColumns.time} ASC',
    );
    return rows.map(_mealFromMap).toList();
  }

  Future<List<Symptom>> getSymptoms(int fascicoloId, DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      cachedSymptomTable,
      where: '${CacheColumns.fascicoloId} = ? AND ${CacheColumns.date} = ?',
      whereArgs: [fascicoloId, _dateKey(date)],
      orderBy: '${CacheColumns.time} ASC',
    );
    return rows.map(_symptomFromMap).toList();
  }

  /// Entrambe le tabelle del giorno (parità con [upsertDay]).
  Future<({List<Meal> meals, List<Symptom> symptoms})> getDay(
      int fascicoloId, DateTime date) async {
    final meals = await getMeals(fascicoloId, date);
    final symptoms = await getSymptoms(fascicoloId, date);
    return (meals: meals, symptoms: symptoms);
  }

  /// `true` se la giornata è già stata scaricata dal backend almeno una volta:
  /// permette al ramo offline dei repository di servire una lista vuota
  /// (giornata sincronizzata e senza voci) invece di un errore di rete (RF11).
  Future<bool> isDaySynced(int fascicoloId, DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      syncedDayTable,
      where: '${CacheColumns.fascicoloId} = ? AND ${CacheColumns.date} = ?',
      whereArgs: [fascicoloId, _dateKey(date)],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Marca [dateKey]/[fascicoloId] come sincronizzata. Va eseguita nella stessa
  /// transazione della scrittura cache-aside del giorno così marcatore e righe
  /// restano coerenti.
  Future<void> _markDaySynced(
          DatabaseExecutor txn, int fascicoloId, String dateKey) =>
      txn.insert(
        syncedDayTable,
        {CacheColumns.fascicoloId: fascicoloId, CacheColumns.date: dateKey},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Svuota tutta la cache, marcatori di sincronizzazione inclusi (logout — RF4).
  Future<void> clear() async {
    final db = await _db;
    await db.delete(cachedMealTable);
    await db.delete(cachedSymptomTable);
    await db.delete(syncedDayTable);
  }

  // --- row <-> domain ---

  Map<String, Object?> _mealToMap(Meal meal, int fascicoloId, String dateKey) {
    final totals = meal.totals ?? NutrientTotals.zero;
    return {
      CacheColumns.id: meal.id,
      CacheColumns.fascicoloId: fascicoloId,
      CacheColumns.date: dateKey,
      CacheColumns.time: meal.time,
      CacheColumns.mealType: meal.type.name,
      CacheColumns.lactose: totals.lactose,
      CacheColumns.sorbitol: totals.sorbitol,
      CacheColumns.gluten: totals.gluten,
      CacheColumns.kcal: totals.kcal,
    };
  }

  /// Ricostruisce un [Meal] con `items` vuoto (la cache tiene solo i totali).
  Meal _mealFromMap(Map<String, Object?> row) => Meal(
        id: row[CacheColumns.id] as int,
        fascicoloId: row[CacheColumns.fascicoloId] as int,
        date: DateTime.parse(row[CacheColumns.date] as String),
        time: row[CacheColumns.time] as String,
        type: MealType.values.byName(row[CacheColumns.mealType] as String),
        items: const [],
        totals: NutrientTotals(
          lactose: (row[CacheColumns.lactose] as num).toDouble(),
          sorbitol: (row[CacheColumns.sorbitol] as num).toDouble(),
          gluten: (row[CacheColumns.gluten] as num).toDouble(),
          kcal: (row[CacheColumns.kcal] as num).toDouble(),
        ),
      );

  Map<String, Object?> _symptomToMap(
          Symptom symptom, int fascicoloId, String dateKey) =>
      {
        CacheColumns.id: symptom.id,
        CacheColumns.fascicoloId: fascicoloId,
        CacheColumns.date: dateKey,
        CacheColumns.time: symptom.time,
        CacheColumns.symptomType: symptom.type.name,
        CacheColumns.severity: symptom.severity.name,
      };

  Symptom _symptomFromMap(Map<String, Object?> row) => Symptom(
        id: row[CacheColumns.id] as int,
        fascicoloId: row[CacheColumns.fascicoloId] as int,
        date: DateTime.parse(row[CacheColumns.date] as String),
        time: row[CacheColumns.time] as String,
        type:
            SymptomType.values.byName(row[CacheColumns.symptomType] as String),
        severity: SymptomSeverity.values
            .byName(row[CacheColumns.severity] as String),
      );
}
