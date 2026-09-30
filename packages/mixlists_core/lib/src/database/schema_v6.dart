import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Adds `Songs.creditedArtist` (the song's own artist when it isn't the
/// album artist: compilations, splits; null means "the album artist"),
/// `Artists.imageURL` and `Mixlists.imageURL`. Skips existing columns.
Future<void> applySchemaV6(Database db) async {
  await _addColumnIfMissing(
    db,
    'Songs',
    'creditedArtist',
    'INTEGER REFERENCES Artists(id)',
  );
  await _addColumnIfMissing(db, 'Artists', 'imageURL', 'TEXT');
  await _addColumnIfMissing(db, 'Mixlists', 'imageURL', 'TEXT');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_songs_credited_artist '
    'ON Songs(creditedArtist)',
  );
}

Future<void> _addColumnIfMissing(
  Database db,
  String table,
  String column,
  String type,
) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  if (!columns.any((c) => c['name'] == column)) {
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }
}
