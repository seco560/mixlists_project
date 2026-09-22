import 'package:mixlists_core/mixlists_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database db;
  late MixlistIngestion ingestion;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await createSchemaV2(db);
    await applySchemaV3(db);
    await applySchemaV4(db);
    ingestion = MixlistIngestion(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('getOrCreateAlbumId', () {
    test('reuses an existing row when spotifyURI matches exactly', () async {
      final artistId = await db.insert('Artists', {'name': 'Some Artist'});
      final firstId = await ingestion.getOrCreateAlbumId(
        db,
        spotifyURI: 'spotify:album:a',
        name: 'Some Album',
        releaseDate: '2020',
        coverImageURL: null,
        artistId: artistId,
      );
      final secondId = await ingestion.getOrCreateAlbumId(
        db,
        spotifyURI: 'spotify:album:a',
        name: 'Some Album',
        releaseDate: '2020',
        coverImageURL: null,
        artistId: artistId,
      );
      expect(secondId, firstId);
      final rows = await db.query('Albums');
      expect(rows, hasLength(1));
    });

    test('falls back to (name, artist) and adopts the row when a different '
        'spotifyURI is served for what is really the same album', () async {
      final artistId = await db.insert('Artists', {'name': 'Some Artist'});
      final originalId = await ingestion.getOrCreateAlbumId(
        db,
        spotifyURI: 'spotify:album:old-uri',
        name: 'Reissued Album',
        releaseDate: '2010',
        coverImageURL: null,
        artistId: artistId,
      );

      final resultId = await ingestion.getOrCreateAlbumId(
        db,
        spotifyURI: 'spotify:album:new-uri',
        name: 'Reissued Album',
        releaseDate: '2010',
        coverImageURL: null,
        artistId: artistId,
      );

      expect(
        resultId,
        originalId,
        reason: 'adopts the existing row, does not insert a new one',
      );
      final rows = await db.query('Albums');
      expect(rows, hasLength(1));
      expect(
        rows.first['spotifyURI'],
        'spotify:album:new-uri',
        reason: 'the row\'s spotifyURI is refreshed to the newly-seen value',
      );
    });

    test(
      'does not merge across different artists even with the same album name',
      () async {
        final artistA = await db.insert('Artists', {'name': 'Artist A'});
        final artistB = await db.insert('Artists', {'name': 'Artist B'});
        await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:a1',
          name: 'Greatest Hits',
          releaseDate: '2001',
          coverImageURL: null,
          artistId: artistA,
        );
        await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:b1',
          name: 'Greatest Hits',
          releaseDate: '2002',
          coverImageURL: null,
          artistId: artistB,
        );

        final rows = await db.query('Albums');
        expect(rows, hasLength(2));
      },
    );

    test(
      'inserts fresh (does not guess) when the name matches 2+ existing rows',
      () async {
        final artistId = await db.insert('Artists', {'name': 'Some Artist'});
        // Two pre-existing URI-less rows with the same name -- ambiguous.
        await db.insert('Albums', {'name': 'Untitled', 'artist': artistId});
        await db.insert('Albums', {'name': 'Untitled', 'artist': artistId});

        final resultId = await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:new',
          name: 'Untitled',
          releaseDate: '2020',
          coverImageURL: null,
          artistId: artistId,
        );

        final rows = await db.query('Albums');
        expect(
          rows,
          hasLength(3),
          reason: 'ambiguous match inserts a new row rather than guessing',
        );
        expect(
          rows.any(
            (r) =>
                r['id'] == resultId && r['spotifyURI'] == 'spotify:album:new',
          ),
          isTrue,
        );
      },
    );

    test(
      'backfills recordLabel only if the existing row does not already have one',
      () async {
        final artistId = await db.insert('Artists', {'name': 'Some Artist'});
        final albumId = await db.insert('Albums', {
          'name': 'Some Album',
          'artist': artistId,
          'recordLabel': 'Original Label',
        });

        await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:x',
          name: 'Some Album',
          releaseDate: '2020',
          coverImageURL: null,
          artistId: artistId,
          recordLabel: 'New Label',
        );

        final row = (await db.query(
          'Albums',
          where: 'id = ?',
          whereArgs: [albumId],
        )).first;
        expect(row['recordLabel'], 'Original Label');
      },
    );
  });

  group('getOrCreateSongId', () {
    /// Regression: two "Note to Self" songs by different artists with close
    /// durations used to be collapsed into one Songs row.
    test(
      'does not merge same-titled songs by different artists via the library-wide fallback',
      () async {
        final artistA = await db.insert('Artists', {
          'name': 'Thanks, But Anyway',
        });
        final albumA = await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:a',
          name: "It's Something",
          releaseDate: '2018',
          coverImageURL: null,
          artistId: artistA,
        );
        final firstSongId = await ingestion.getOrCreateSongId(
          db,
          spotifyURI: 'spotify:track:thanks-but-anyway-note-to-self',
          name: 'Note to Self',
          artists: 'Thanks, But Anyway',
          artistsURIs: null,
          albumId: albumA,
          durationMs: 229506,
          buildExtraData: (songId) => SongExtraData(
            id: 0,
            discNumber: null,
            albumTrackNumber: null,
            durationMs: 229506,
            audioPreviewURL: null,
            isExplicit: true,
            popularity: null,
            isrc: null,
            songID: songId,
          ),
        );

        final artistB = await db.insert('Artists', {'name': 'Modern Baseball'});
        final albumB = await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:b',
          name: 'Some Other Album',
          releaseDate: '2014',
          coverImageURL: null,
          artistId: artistB,
        );
        // A different song, same title, duration within the 1000ms
        // tolerance of the first one.
        final secondSongId = await ingestion.getOrCreateSongId(
          db,
          spotifyURI: 'spotify:track:modern-baseball-note-to-self',
          name: 'Note to Self',
          artists: 'Modern Baseball',
          artistsURIs: null,
          albumId: albumB,
          durationMs: 229900,
          buildExtraData: (songId) => SongExtraData(
            id: 0,
            discNumber: null,
            albumTrackNumber: null,
            durationMs: 229900,
            audioPreviewURL: null,
            isExplicit: false,
            popularity: null,
            isrc: null,
            songID: songId,
          ),
        );

        expect(
          secondSongId,
          isNot(firstSongId),
          reason: 'two different songs, not a merge',
        );
        final rows = await db.query('Songs');
        expect(rows, hasLength(2));
        final firstRow = rows.firstWhere((r) => r['id'] == firstSongId);
        expect(
          firstRow['spotifyURI'],
          'spotify:track:thanks-but-anyway-note-to-self',
          reason: 'unrelated to the second import, must not be reassigned',
        );
      },
    );

    test(
      'still merges the same track re-served under a different album (library-wide, same artist)',
      () async {
        final artist = await db.insert('Artists', {'name': 'Some Artist'});
        final albumOriginal = await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:original',
          name: 'Original Album',
          releaseDate: '2015',
          coverImageURL: null,
          artistId: artist,
        );
        final originalSongId = await ingestion.getOrCreateSongId(
          db,
          spotifyURI: 'spotify:track:old-uri',
          name: 'Some Song',
          artists: 'Some Artist',
          artistsURIs: null,
          albumId: albumOriginal,
          durationMs: 180000,
          buildExtraData: (songId) => SongExtraData(
            id: 0,
            discNumber: null,
            albumTrackNumber: null,
            durationMs: 180000,
            audioPreviewURL: null,
            isExplicit: false,
            popularity: null,
            isrc: null,
            songID: songId,
          ),
        );

        final albumCompilation = await ingestion.getOrCreateAlbumId(
          db,
          spotifyURI: 'spotify:album:compilation',
          name: 'Greatest Hits Compilation',
          releaseDate: '2020',
          coverImageURL: null,
          artistId: artist,
        );
        final resultId = await ingestion.getOrCreateSongId(
          db,
          spotifyURI: 'spotify:track:new-uri',
          name: 'Some Song',
          artists: 'Some Artist',
          artistsURIs: null,
          albumId: albumCompilation,
          durationMs: 180200,
          buildExtraData: (songId) => SongExtraData(
            id: 0,
            discNumber: null,
            albumTrackNumber: null,
            durationMs: 180200,
            audioPreviewURL: null,
            isExplicit: false,
            popularity: null,
            isrc: null,
            songID: songId,
          ),
        );

        expect(resultId, originalSongId);
        final rows = await db.query('Songs');
        expect(rows, hasLength(1));
      },
    );
  });
}
