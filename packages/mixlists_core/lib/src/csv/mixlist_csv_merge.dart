import 'mixlist_csv_parser.dart';

/// Merges two parsed exports of the *same* mixlist that came from
/// different formats -- e.g. an older app-native export (rich in URIs,
/// album art, preview URLs, ISRC, disc/track numbers) and a newer
/// Exportify-style export (rich in genres, record label, audio features)
/// -- into one row set carrying whichever fields each side actually has.
///
/// Rows are matched by [MixlistCsvRow.trackURI], which is stable across
/// both formats. [primary]'s row order and any field it has non-null wins;
/// [secondary] only fills in fields [primary] left null. A track present
/// in only one file is kept as-is. Playlist order follows [primary]'s
/// order, with any secondary-only tracks appended at the end (this should
/// be rare -- it means the two exports were taken far enough apart that
/// the playlist itself changed in between).
List<MixlistCsvRow> mergeMixlistCsvRows(
  List<MixlistCsvRow> primary,
  List<MixlistCsvRow> secondary,
) {
  final secondaryByUri = {for (final row in secondary) row.trackURI: row};

  final merged = [
    for (final row in primary) _mergeRow(row, secondaryByUri[row.trackURI]),
  ];

  final primaryUris = primary.map((r) => r.trackURI).toSet();
  merged.addAll(secondary.where((row) => !primaryUris.contains(row.trackURI)));

  return merged;
}

MixlistCsvRow _mergeRow(MixlistCsvRow primary, MixlistCsvRow? secondary) {
  if (secondary == null) return primary;
  return MixlistCsvRow(
    trackURI: primary.trackURI,
    trackName: primary.trackName,
    artistURIs: primary.artistURIs ?? secondary.artistURIs,
    artistNames: primary.artistNames,
    albumURI: primary.albumURI ?? secondary.albumURI,
    albumName: primary.albumName,
    albumArtistURI: primary.albumArtistURI ?? secondary.albumArtistURI,
    albumArtistName: primary.albumArtistName,
    albumReleaseDate: primary.albumReleaseDate ?? secondary.albumReleaseDate,
    albumImageURL: primary.albumImageURL ?? secondary.albumImageURL,
    discNumber: primary.discNumber ?? secondary.discNumber,
    albumTrackNumber: primary.albumTrackNumber ?? secondary.albumTrackNumber,
    durationMs: primary.durationMs,
    audioPreviewURL: primary.audioPreviewURL ?? secondary.audioPreviewURL,
    isExplicit: primary.isExplicit,
    popularity: primary.popularity ?? secondary.popularity,
    isrc: primary.isrc ?? secondary.isrc,
    addedAt: primary.addedAt,
    genres: primary.genres ?? secondary.genres,
    recordLabel: primary.recordLabel ?? secondary.recordLabel,
    danceability: primary.danceability ?? secondary.danceability,
    energy: primary.energy ?? secondary.energy,
    key: primary.key ?? secondary.key,
    loudness: primary.loudness ?? secondary.loudness,
    mode: primary.mode ?? secondary.mode,
    speechiness: primary.speechiness ?? secondary.speechiness,
    acousticness: primary.acousticness ?? secondary.acousticness,
    instrumentalness: primary.instrumentalness ?? secondary.instrumentalness,
    liveness: primary.liveness ?? secondary.liveness,
    valence: primary.valence ?? secondary.valence,
    tempo: primary.tempo ?? secondary.tempo,
    timeSignature: primary.timeSignature ?? secondary.timeSignature,
  );
}
