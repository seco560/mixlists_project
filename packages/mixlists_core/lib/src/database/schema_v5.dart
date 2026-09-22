import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Adds `Mixlists.is_mixlists` (0/1): whether the user marked the playlist
/// as a curated mixlist via "Mark Mixlists". Defaults to 0.
Future<void> applySchemaV5(Database db) async {
  await db.execute(
    'ALTER TABLE Mixlists ADD COLUMN is_mixlists INTEGER NOT NULL DEFAULT 0',
  );
}
