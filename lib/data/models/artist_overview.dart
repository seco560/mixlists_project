import 'album_summary.dart';
import 'mixlist_summary.dart';

class ArtistOverview {
  const ArtistOverview({
    required this.id,
    required this.name,
    required this.albums,
    required this.mixlists,
    required this.uniqueSongCount,
    required this.appearanceCount,
    required this.genres,
  });

  final int id;
  final String name;
  final List<AlbumSummary> albums;
  final List<MixlistSummary> mixlists;

  final int uniqueSongCount;

  final int appearanceCount;

  /// Parsed from `Artists.genres` (a comma-joined string) -- empty when
  /// Spotify returned none for this artist.
  final List<String> genres;
}
