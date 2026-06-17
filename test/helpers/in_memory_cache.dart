import 'package:nutrease_flutter/data/local/diary_cache_dao.dart';
import 'package:nutrease_flutter/data/local/diary_cache_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A [DiaryCacheDao] backed by a fresh in-memory SQLite database (FFI), so the
/// cache is unit-testable without a device. Each call returns an isolated DB:
/// `singleInstance: false` is required, otherwise repeated opens of the shared
/// `:memory:` path would hand back the same database and leak state across tests.
DiaryCacheDao buildInMemoryCacheDao() {
  sqfliteFfiInit();
  return DiaryCacheDao(
    open: () => databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: diaryCacheDbVersion,
        singleInstance: false,
        onCreate: (db, _) => createDiaryCacheSchema(db),
      ),
    ),
  );
}
