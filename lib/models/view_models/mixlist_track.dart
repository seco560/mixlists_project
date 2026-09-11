/// Shows pretty well why extra song data does not really need to be its own
/// separate table. Most useful queries use data from there anyway.
class MixlistTrack {
  const MixlistTrack({
    required this.position,
    required this.dateAdded,
    required this.songId,
    required this.songSpotifyURI,
    required this.songName,
    required this.artistNames,
    required this.artistURIs,
    required this.artistId,
    required this.albumId,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.albumReleaseDate,
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

  final int artistId;
  final int albumId;
  final String albumName;
  final String albumCoverImageURL;
  final String albumReleaseDate;

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
      artistId: map['artistId'] as int,
      albumId: map['albumId'] as int,
      albumName: map['albumName'] as String,
      albumCoverImageURL: map['albumCoverImageURL'] as String,
      albumReleaseDate: map['albumReleaseDate'] as String,
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
