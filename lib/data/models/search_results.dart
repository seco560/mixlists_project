import 'package:mixlists_core/mixlists_core.dart';

import 'album_overview.dart';
import 'artist_overview.dart';
import 'song_search_result.dart';

class SearchResults {
  const SearchResults({
    required this.mixlists,
    required this.artists,
    required this.genres,
    required this.albums,
    required this.labels,
    required this.songs,
  });

  final List<Mixlist> mixlists;
  final List<ArtistOverview> artists;
  final List<String> genres;
  final List<AlbumOverview> albums;
  final List<String> labels;
  final List<SongSearchResult> songs;

  bool get isEmpty =>
      mixlists.isEmpty &&
      artists.isEmpty &&
      genres.isEmpty &&
      albums.isEmpty &&
      labels.isEmpty &&
      songs.isEmpty;
}
