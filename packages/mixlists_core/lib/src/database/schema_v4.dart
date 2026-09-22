import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Partial unique indexes on the `spotifyURI` columns (where not null), the
/// main get-or-create lookup key. Each is created separately and a failure
/// (duplicate URIs in older dbs) is only a warning, not a failed migration.
Future<void> applySchemaV4(Database db) async {
  await _tryCreateUniqueIndex(
    db,
    'idx_artists_spotify_uri',
    'Artists',
    'spotifyURI',
  );
  await _tryCreateUniqueIndex(
    db,
    'idx_albums_spotify_uri',
    'Albums',
    'spotifyURI',
  );
  await _tryCreateUniqueIndex(
    db,
    'idx_songs_spotify_uri',
    'Songs',
    'spotifyURI',
  );
}

Future<void> _tryCreateUniqueIndex(
  Database db,
  String indexName,
  String table,
  String column,
) async {
  try {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS $indexName ON $table($column) '
      'WHERE $column IS NOT NULL',
    );
  } on DatabaseException catch (e) {
    // ignore: avoid_print
    print(
      'Warning: could not create $indexName ($table.$column has duplicate '
      'non-null values) -- skipping. $e',
    );
  }
}
