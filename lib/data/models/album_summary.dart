class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.coverImageURL,
    required this.recordLabel,
  });

  final int id;
  final String name;
  final String releaseDate;
  final String? coverImageURL;
  final String? recordLabel;
}
