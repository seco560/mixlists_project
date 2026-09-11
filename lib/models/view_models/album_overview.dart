class AlbumOverview {
  const AlbumOverview({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.coverImageURL,
    required this.artistId,
    required this.artistName,
  });

  final int id;
  final String name;
  final String releaseDate;
  final String coverImageURL;
  final int artistId;
  final String artistName;

  factory AlbumOverview.fromMap(Map<String, Object?> map) {
    return AlbumOverview(
      id: map['id'] as int,
      name: map['name'] as String,
      releaseDate: map['releaseDate'] as String,
      coverImageURL: map['coverImageURL'] as String,
      artistId: map['artistId'] as int,
      artistName: map['artistName'] as String,
    );
  }
}
