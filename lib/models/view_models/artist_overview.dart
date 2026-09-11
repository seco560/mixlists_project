import 'album_summary.dart';
import 'mixlist_summary.dart';

// Also a "view-model" used to show detailed artist information
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

  /// Distinct songs by this artist that appear in at least one mixlist --
  /// i.e. `COUNT(DISTINCT song)`, not the number of (song, mixlist) pairs.
  final int uniqueSongCount;

  /// The number of (song, mixlist) pairs -- every time one of this
  /// artist's songs was added to a mixlist, counted once per mixlist. A
  /// song on 3 mixlists contributes 3 here but 1 to [uniqueSongCount].
  final int appearanceCount;
}
