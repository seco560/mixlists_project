import 'package:mixlists_project/data/filter/mixlist_filter.dart';

/// Whether each artist/album/genre/label appears on a mixlist and/or a plain
/// playlist, built in one pass. Cached by the repository and carried on
/// [SearchResults] to re-scope searches in memory on filter change.
class MixlistScopeIndex {
  const MixlistScopeIndex({
    required this.mixlistArtistIds,
    required this.playlistArtistIds,
    required this.mixlistAlbumIds,
    required this.playlistAlbumIds,
    required this.mixlistGenres,
    required this.playlistGenres,
    required this.mixlistLabels,
    required this.playlistLabels,
  });

  const MixlistScopeIndex.empty()
    : mixlistArtistIds = const {},
      playlistArtistIds = const {},
      mixlistAlbumIds = const {},
      playlistAlbumIds = const {},
      mixlistGenres = const {},
      playlistGenres = const {},
      mixlistLabels = const {},
      playlistLabels = const {};

  final Set<int> mixlistArtistIds;
  final Set<int> playlistArtistIds;
  final Set<int> mixlistAlbumIds;
  final Set<int> playlistAlbumIds;
  final Set<String> mixlistGenres;
  final Set<String> playlistGenres;
  final Set<String> mixlistLabels;
  final Set<String> playlistLabels;

  bool artistQualifies(MixlistFilter filter, int artistId) =>
      _qualifies(filter, artistId, mixlistArtistIds, playlistArtistIds);

  bool albumQualifies(MixlistFilter filter, int albumId) =>
      _qualifies(filter, albumId, mixlistAlbumIds, playlistAlbumIds);

  bool genreQualifies(MixlistFilter filter, String genre) =>
      _qualifies(filter, genre, mixlistGenres, playlistGenres);

  bool labelQualifies(MixlistFilter filter, String label) =>
      _qualifies(filter, label, mixlistLabels, playlistLabels);

  bool _qualifies<T>(
    MixlistFilter filter,
    T key,
    Set<T> mixlistKeys,
    Set<T> playlistKeys,
  ) => switch (filter) {
    MixlistFilter.all => true,
    MixlistFilter.mixlistsOnly => mixlistKeys.contains(key),
    MixlistFilter.nonMixlistsOnly => playlistKeys.contains(key),
  };
}
