/// An Album paired with its artist's name, for screens that list every
/// album across every artist and need to sort/show by artist without a
/// second lookup per row.
///
/// Unlike [Album], this isn't backed by one table -- it's the shape of a
/// SQL JOIN across Albums and Artists (see
/// MusicLibraryRepository.getAlbumOverviews()).
class AlbumOverview {
  const AlbumOverview({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.coverImageURL,
    required this.artistName,
  });

  final int id;
  final String name;
  final String releaseDate;
  final String coverImageURL;
  final String artistName;

  factory AlbumOverview.fromMap(Map<String, Object?> map) {
    return AlbumOverview(
      id: map['id'] as int,
      name: map['name'] as String,
      releaseDate: map['releaseDate'] as String,
      coverImageURL: map['coverImageURL'] as String,
      artistName: map['artistName'] as String,
    );
  }
}
