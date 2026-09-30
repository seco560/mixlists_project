class Song {
  final int id;
  final String spotifyURI;
  final String name;
  final String artists;
  final String? artistsURIs;
  final int albumID;

  /// The song's own artist when it isn't the album artist; null otherwise.
  final int? creditedArtistID;

  Song({
    required this.id,
    required this.spotifyURI,
    required this.name,
    required this.artists,
    required this.artistsURIs,
    required this.albumID,
    this.creditedArtistID,
  });

  factory Song.fromMap(Map<String, Object?> map) {
    return Song(
      id: map['id'] as int,
      spotifyURI: map['spotifyURI'] as String,
      name: map['name'] as String,
      artists: map['artists'] as String,
      artistsURIs: map['artistsURIs'] as String?,
      albumID: map['album'] as int,
      creditedArtistID: map['creditedArtist'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'spotifyURI': spotifyURI,
      'name': name,
      'artists': artists,
      'artistsURIs': artistsURIs,
      'album': albumID,
      'creditedArtist': creditedArtistID,
    };
  }
}
