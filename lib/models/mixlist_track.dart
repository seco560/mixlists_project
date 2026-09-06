/// A single track within a mixlist, carrying the song/album/artist and
/// audio-metadata fields a track-list or player screen needs.
///
/// Unlike [Song], [Album], etc., this isn't backed by one table -- it's
/// the shape of a SQL JOIN across SongsMixlists, Songs, Albums, and
/// SongsExtraData (see MusicLibraryRepository.getTracksForMixlist).
/// Building a small purpose-built class like this for a query result,
/// instead of trying to force the row into one of the table models, is
/// the usual pattern once a query stops being "all/some columns of one
/// table."
class MixlistTrack {
  const MixlistTrack({
    required this.position,
    required this.dateAdded,
    required this.songId,
    required this.songSpotifyURI,
    required this.songName,
    required this.artistNames,
    required this.artistURIs,
    required this.albumId,
    required this.albumName,
    required this.albumCoverImageURL,
    this.durationMs,
    this.isExplicit,
    this.popularity,
    this.audioPreviewURL,
  });

  final int position;
  final String dateAdded;
  final int songId;
  final String songSpotifyURI;
  final String songName;
  final String artistNames;
  final String artistURIs;
  final int albumId;
  final String albumName;
  final String albumCoverImageURL;

  // Nullable: these come from a LEFT JOIN against SongsExtraData, so a
  // song without an extra-data row (none exist in the current seed data,
  // but nothing guarantees that -- there's no enforced foreign key, see
  // CHANGES.md) still shows up in the track list instead of vanishing.
  final int? durationMs;
  final bool? isExplicit;
  final int? popularity;
  final String? audioPreviewURL;

  factory MixlistTrack.fromMap(Map<String, Object?> map) {
    final explicitText = map['explicit'] as String?;
    return MixlistTrack(
      position: map['positionIndex'] as int,
      dateAdded: map['dateAdded'] as String,
      songId: map['songId'] as int,
      songSpotifyURI: map['songSpotifyURI'] as String,
      songName: map['songName'] as String,
      artistNames: map['artists'] as String,
      artistURIs: map['artistsURIs'] as String,
      albumId: map['albumId'] as int,
      albumName: map['albumName'] as String,
      albumCoverImageURL: map['albumCoverImageURL'] as String,
      durationMs: map['durationMs'] as int?,
      isExplicit: explicitText == null
          ? null
          : explicitText.toLowerCase() == 'true',
      popularity: map['popularity'] as int?,
      audioPreviewURL: map['audioPreviewURL'] as String?,
    );
  }

  @override
  String toString() {
    return "$position) $artistNames - $songName [from $albumName] | ${(durationMs! / 1000 / 60).toInt()}:${(durationMs! / 1000 % 60).toInt()}";
  }
}
