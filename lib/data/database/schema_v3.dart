import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Adds the columns/table the "richer" CSV export format needs (genres,
/// record label, per-track audio features) on top of schema V2. Kept in
/// its own file with no Flutter-package imports (unlike app_database.dart,
/// which needs path_provider/rootBundle) so it's usable both from the app
/// and from `bin/backfill_new_format_data.dart`, a plain `dart run` script
/// that can't resolve Flutter/dart:ui imports -- this keeps the two paths
/// from drifting apart.
Future<void> applySchemaV3(Database db) async {
  await db.execute('ALTER TABLE Artists ADD COLUMN genres TEXT');
  await db.execute('ALTER TABLE Albums ADD COLUMN recordLabel TEXT');
  await db.execute('''
    CREATE TABLE SongsAudioFeatures (
      id INTEGER PRIMARY KEY,
      song INTEGER UNIQUE,
      danceability REAL,
      energy REAL,
      key INTEGER,
      loudness REAL,
      mode INTEGER,
      speechiness REAL,
      acousticness REAL,
      instrumentalness REAL,
      liveness REAL,
      valence REAL,
      tempo REAL,
      timeSignature INTEGER,
      FOREIGN KEY(song) REFERENCES Songs(id)
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_audio_features_song ON SongsAudioFeatures(song)',
  );
}
