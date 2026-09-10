class Album {
  final int id;
  final String spotifyURI;
  final String name;
  final String releaseDate;
  final String coverImageURL;
  final int artistID;

  const Album({
    required this.id,
    required this.spotifyURI,
    required this.name,
    required this.releaseDate,
    required this.coverImageURL,
    required this.artistID,
  });

  factory Album.fromMap(Map<String, Object?> map) {
    return Album(
      id: map['id'] as int,
      spotifyURI: map['spotifyURI'] as String,
      name: map['name'] as String,
      releaseDate: map['releaseDate'] as String,
      coverImageURL: map['coverImageURL'] as String,
      artistID: map['artist'] as int,
    );
  }
 
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'spotifyURI': spotifyURI,
      'name': name,
      'releaseDate': releaseDate,
      'coverImageURL': coverImageURL,
      'artist': artistID,
    };
  }
}
