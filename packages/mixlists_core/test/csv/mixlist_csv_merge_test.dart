import 'package:mixlists_core/mixlists_core.dart';
import 'package:test/test.dart';

MixlistCsvRow _row({
  required String trackURI,
  String? artistURIs,
  String? albumURI,
  String? albumImageURL,
  int? discNumber,
  int? albumTrackNumber,
  String? audioPreviewURL,
  int? popularity,
  String? isrc,
  String? genres,
  String? recordLabel,
  double? danceability,
}) {
  return MixlistCsvRow(
    trackURI: trackURI,
    trackName: 'Some Song',
    artistURIs: artistURIs,
    artistNames: 'Some Artist',
    albumURI: albumURI,
    albumName: 'Some Album',
    albumArtistURI: null,
    albumArtistName: 'Some Artist',
    albumReleaseDate: '2020-01-01',
    albumImageURL: albumImageURL,
    discNumber: discNumber,
    albumTrackNumber: albumTrackNumber,
    durationMs: 180000,
    audioPreviewURL: audioPreviewURL,
    isExplicit: false,
    popularity: popularity,
    isrc: isrc,
    addedAt: '2023-01-01T00:00:00Z',
    genres: genres,
    recordLabel: recordLabel,
    danceability: danceability,
    energy: null,
    key: null,
    loudness: null,
    mode: null,
    speechiness: null,
    acousticness: null,
    instrumentalness: null,
    liveness: null,
    valence: null,
    tempo: null,
    timeSignature: null,
  );
}

void main() {
  test(
    'fills null fields on the primary row from the matching secondary row',
    () {
      final primary = [
        _row(
          trackURI: 'spotify:track:1',
          artistURIs: 'spotify:artist:1',
          albumURI: 'spotify:album:1',
          albumImageURL: 'https://img/1.jpg',
          discNumber: 1,
          albumTrackNumber: 2,
          audioPreviewURL: 'https://preview/1.mp3',
          isrc: 'ISRC1',
        ),
      ];
      final secondary = [
        _row(
          trackURI: 'spotify:track:1',
          genres: 'skate punk',
          recordLabel: 'Some Label',
          danceability: 0.6,
        ),
      ];

      final merged = mergeMixlistCsvRows(primary, secondary);

      expect(merged, hasLength(1));
      final row = merged.single;
      // Primary-only fields survive.
      expect(row.artistURIs, 'spotify:artist:1');
      expect(row.albumURI, 'spotify:album:1');
      expect(row.isrc, 'ISRC1');
      // Secondary-only fields get filled in.
      expect(row.genres, 'skate punk');
      expect(row.recordLabel, 'Some Label');
      expect(row.danceability, 0.6);
    },
  );

  test(
    'does not let a null secondary field clobber a non-null primary field',
    () {
      final primary = [
        _row(trackURI: 'spotify:track:1', genres: 'from primary'),
      ];
      final secondary = [_row(trackURI: 'spotify:track:1', genres: null)];

      final merged = mergeMixlistCsvRows(primary, secondary);

      expect(merged.single.genres, 'from primary');
    },
  );

  test('keeps a track present only in the primary file', () {
    final primary = [_row(trackURI: 'spotify:track:only-primary')];
    final secondary = <MixlistCsvRow>[];

    final merged = mergeMixlistCsvRows(primary, secondary);

    expect(merged, hasLength(1));
    expect(merged.single.trackURI, 'spotify:track:only-primary');
  });

  test(
    'appends a track present only in the secondary file, after the primary ones',
    () {
      final primary = [_row(trackURI: 'spotify:track:a')];
      final secondary = [
        _row(trackURI: 'spotify:track:a'),
        _row(trackURI: 'spotify:track:only-secondary'),
      ];

      final merged = mergeMixlistCsvRows(primary, secondary);

      expect(merged.map((r) => r.trackURI), [
        'spotify:track:a',
        'spotify:track:only-secondary',
      ]);
    },
  );

  test('preserves the primary order for tracks present in both', () {
    final primary = [
      _row(trackURI: 'spotify:track:2'),
      _row(trackURI: 'spotify:track:1'),
    ];
    final secondary = [
      _row(trackURI: 'spotify:track:1'),
      _row(trackURI: 'spotify:track:2'),
    ];

    final merged = mergeMixlistCsvRows(primary, secondary);

    expect(merged.map((r) => r.trackURI), [
      'spotify:track:2',
      'spotify:track:1',
    ]);
  });
}
