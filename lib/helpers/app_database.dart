import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _dbAssetPath = 'assets/database/mixlists.db';
const String _dbFileName = 'mixlists.db';

const int _dbVersion = 2; // Claude proudly noticed my FKs singular misspelling

Future<Database> openAppDatabase() async {
  _initFfiIfNeeded();

  final appDirectory = Platform.isIOS
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  final path = join(appDirectory.path, _dbFileName);

  if (!await File(path).exists()) {
    await _copyDatabaseFromAssets(path);
  }

  return openDatabase(
    path,
    version: _dbVersion,
    onConfigure: (db) async {},
    onCreate: (db, version) async {
      await _createSchemaV2(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_albums_artist ON Albums(artist)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_songs_album ON Songs(album)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_extra_song ON SongsExtraData(song)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sm_mixlist ON SongsMixlists(mixlist)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sm_song ON SongsMixlists(song)',
        );
      }
    },
  );
}

void _initFfiIfNeeded() {
  if (Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<void> _copyDatabaseFromAssets(String destinationPath) async {
  try {
    await Directory(dirname(destinationPath)).create(recursive: true);
    final data = await rootBundle.load(_dbAssetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(destinationPath).writeAsBytes(bytes);
  } catch (e) {
    if (kDebugMode) print('Error copying database from assets: $e');
    rethrow;
  }
}

/// Used as back-up in case existing DB becomes inaccessible for whatever reason.
Future<void> _createSchemaV2(Database db) async {
  await db.execute('''
    CREATE TABLE Mixlists (
      id INTEGER PRIMARY KEY,
      title TEXT UNIQUE,
      description TEXT,
      dateCreated TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE Artists (
      id INTEGER PRIMARY KEY,
      spotifyURI TEXT,
      name TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE Albums (
      id INTEGER PRIMARY KEY,
      spotifyURI TEXT,
      name TEXT,
      releaseDate TEXT,
      coverImageURL TEXT,
      artist INTEGER,
      FOREIGN KEY(artist) REFERENCES Artists(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE Songs (
      id INTEGER PRIMARY KEY,
      spotifyURI TEXT,
      name TEXT,
      artists TEXT,
      artistsURIs TEXT,
      album INTEGER,
      FOREIGN KEY(album) REFERENCES Albums(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE SongsExtraData (
      id INTEGER PRIMARY KEY,
      discNumber INT,
      albumTrackNumber INT,
      durationMs INT,
      audioPreviewURL TEXT,
      explicit TEXT,
      popularity INT,
      ISRC TEXT,
      song INTEGER,
      FOREIGN KEY(song) REFERENCES Songs(id)
    )
  ''');
  await db.execute('''
    CREATE TABLE SongsMixlists (
      id INTEGER PRIMARY KEY,
      positionIndex INT,
      dateAdded TEXT,
      song INTEGER,
      mixlist INTEGER,
      FOREIGN KEY(song) REFERENCES Songs(id),
      FOREIGN KEY(mixlist) REFERENCES Mixlists(id)
    )
  ''');
  await db.execute('CREATE INDEX idx_albums_artist ON Albums(artist)');
  await db.execute('CREATE INDEX idx_songs_album ON Songs(album)');
  await db.execute('CREATE INDEX idx_extra_song ON SongsExtraData(song)');
  await db.execute('CREATE INDEX idx_sm_mixlist ON SongsMixlists(mixlist)');
  await db.execute('CREATE INDEX idx_sm_song ON SongsMixlists(song)');
}
