import 'package:auramath/data/services/outbox_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory outbox, run in the test isolate so fake_async controls
/// every await. The in-memory database is shared between opens, so the
/// previous test's one is deleted first.
Future<OutboxDb> memoryOutbox() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await databaseFactory.deleteDatabase(inMemoryDatabasePath);
  return OutboxDb.open(inMemoryDatabasePath);
}
