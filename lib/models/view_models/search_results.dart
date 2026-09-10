import '../entities/mixlist.dart';
import 'album_overview.dart';
import 'artist_overview.dart';
import 'song_search_result.dart';

/// The grouped result of a library-wide search -- one list per entity
/// type, already in the fixed order the Search Results screen renders
/// them: Mixlists, Artists, Albums, Songs.
class SearchResults {
  const SearchResults({
    required this.mixlists,
    required this.artists,
    required this.albums,
    required this.songs,
  });

  final List<Mixlist> mixlists;
  final List<ArtistOverview> artists;
  final List<AlbumOverview> albums;
  final List<SongSearchResult> songs;

  bool get isEmpty =>
      mixlists.isEmpty && artists.isEmpty && albums.isEmpty && songs.isEmpty;
}
