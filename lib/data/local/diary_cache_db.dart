/// Schema `sqflite` per la cache offline del diario, lato lettura (RF11).
///
/// Due tabelle piatte — niente righe alimento annidate: la cache tiene i totali
/// nutrienti aggregati di ogni pasto (il dato clinicamente rilevante), così un
/// giorno già caricato resta leggibile offline. È una lettura offline *parziale*;
/// il dettaglio per alimento è disponibile solo online.
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String cachedMealTable = 'cached_meal';
const String cachedSymptomTable = 'cached_symptom';

/// Marcatore delle giornate già sincronizzate dal backend (RF11): distingue una
/// giornata mai scaricata (offline → errore di rete) da una scaricata e davvero
/// vuota (offline → lista vuota). Chiave composta (IdFascicolo, Data).
const String syncedDayTable = 'synced_day';

/// Versione dello schema cache. Bump a 2: aggiunta `synced_day`. Essendo solo
/// cache, l'upgrade droppa e ricrea (nessun dato da preservare).
const int diaryCacheDbVersion = 2;

/// Nomi colonna in un solo posto così `toMap`/query del DAO restano coerenti.
abstract final class CacheColumns {
  static const String id = 'id';
  static const String fascicoloId = 'fascicolo_id';
  static const String date = 'date'; // yyyy-MM-dd
  static const String time = 'time'; // HH:mm:ss

  // cached_meal
  static const String mealType = 'type'; // MealType.name
  static const String lactose = 'lactose';
  static const String sorbitol = 'sorbitol';
  static const String gluten = 'gluten';
  static const String kcal = 'kcal';

  // cached_symptom
  static const String symptomType = 'type'; // SymptomType.name
  static const String severity = 'severity'; // SymptomSeverity.name
}

/// Crea le tabelle della cache (condivisa dall'opener di produzione e dai test).
Future<void> createDiaryCacheSchema(Database db) async {
  await db.execute('''
    CREATE TABLE $cachedMealTable (
      ${CacheColumns.id} INTEGER NOT NULL,
      ${CacheColumns.fascicoloId} INTEGER NOT NULL,
      ${CacheColumns.date} TEXT NOT NULL,
      ${CacheColumns.time} TEXT NOT NULL,
      ${CacheColumns.mealType} TEXT NOT NULL,
      ${CacheColumns.lactose} REAL NOT NULL DEFAULT 0,
      ${CacheColumns.sorbitol} REAL NOT NULL DEFAULT 0,
      ${CacheColumns.gluten} REAL NOT NULL DEFAULT 0,
      ${CacheColumns.kcal} REAL NOT NULL DEFAULT 0,
      PRIMARY KEY (${CacheColumns.id})
    )
  ''');
  await db.execute('''
    CREATE TABLE $cachedSymptomTable (
      ${CacheColumns.id} INTEGER NOT NULL,
      ${CacheColumns.fascicoloId} INTEGER NOT NULL,
      ${CacheColumns.date} TEXT NOT NULL,
      ${CacheColumns.time} TEXT NOT NULL,
      ${CacheColumns.symptomType} TEXT NOT NULL,
      ${CacheColumns.severity} TEXT NOT NULL,
      PRIMARY KEY (${CacheColumns.id})
    )
  ''');
  await db.execute('''
    CREATE TABLE $syncedDayTable (
      ${CacheColumns.fascicoloId} INTEGER NOT NULL,
      ${CacheColumns.date} TEXT NOT NULL,
      PRIMARY KEY (${CacheColumns.fascicoloId}, ${CacheColumns.date})
    )
  ''');
}

/// Migrazione di sola cache: droppa e ricrea (nessun dato clinico da preservare,
/// il backend è la fonte di verità).
Future<void> upgradeDiaryCacheSchema(Database db) async {
  await db.execute('DROP TABLE IF EXISTS $cachedMealTable');
  await db.execute('DROP TABLE IF EXISTS $cachedSymptomTable');
  await db.execute('DROP TABLE IF EXISTS $syncedDayTable');
  await createDiaryCacheSchema(db);
}

/// Apre il database di cache di produzione sotto il databases path della
/// piattaforma.
///
/// Il path è costruito con `join` per portabilità cross-platform.
Future<Database> openDiaryCacheDb() async {
  final path = join(await getDatabasesPath(), 'nutrease_cache.db');
  return openDatabase(
    path,
    version: diaryCacheDbVersion,
    onCreate: (db, _) => createDiaryCacheSchema(db),
    onUpgrade: (db, _, _) => upgradeDiaryCacheSchema(db),
  );
}
