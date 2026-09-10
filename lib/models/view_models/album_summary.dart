/// Just enough of an Album to show in an artist's album column.
class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.coverImageURL,
  });

  final int id;
  final String name;
  final String releaseDate;
  final String coverImageURL;
}
