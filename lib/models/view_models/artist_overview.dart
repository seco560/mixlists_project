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
  });

  final int id;
  final String name;
  final List<AlbumSummary> albums;
  final List<MixlistSummary> mixlists;

  final int uniqueSongCount;

  final int appearanceCount;
}
