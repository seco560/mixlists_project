import 'package:mixlists_core/mixlists_core.dart';

import '../filter/mixlist_filter.dart';
import 'album_overview.dart';
import 'artist_overview.dart';
import 'mixlist_scope_index.dart';
import 'song_search_result.dart';

class SearchResults {
  const SearchResults({
    required this.mixlists,
    required this.artists,
    required this.genres,
    required this.albums,
    required this.labels,
    required this.songs,
    required this.scopeIndex,
  });

  final List<Mixlist> mixlists;
  final List<ArtistOverview> artists;
  final List<String> genres;
  final List<AlbumOverview> albums;
  final List<String> labels;
  final List<SongSearchResult> songs;

  /// The library-wide mixlist/playlist scope snapshot taken alongside this
  /// search -- carried along purely so [scopedTo] can re-filter every
  /// section in memory without a fresh query.
  final MixlistScopeIndex scopeIndex;

  bool get isEmpty =>
      mixlists.isEmpty &&
      artists.isEmpty &&
      genres.isEmpty &&
      albums.isEmpty &&
      labels.isEmpty &&
      songs.isEmpty;

  /// Re-scopes these results to [filter] in memory, no query. Mixlists scope
  /// by their own `isMixlist`, other entities via [scopeIndex]; anything left
  /// with no in-scope appearance is dropped, like the SQL-filtered screens.
  SearchResults scopedTo(MixlistFilter filter) {
    if (filter == MixlistFilter.all) return this;

    final scopedSongs = <SongSearchResult>[];
    for (final song in songs) {
      final scopedMixlists = [
        for (final m in song.mixlists)
          if (filter.matches(m.isMixlist ?? true)) m,
      ];
      if (scopedMixlists.isEmpty) continue;
      scopedSongs.add(
        SongSearchResult(
          songId: song.songId,
          songName: song.songName,
          albumName: song.albumName,
          albumCoverImageURL: song.albumCoverImageURL,
          artistNames: song.artistNames,
          mixlists: scopedMixlists,
          isExplicit: song.isExplicit,
        ),
      );
    }

    return SearchResults(
      mixlists: [
        for (final m in mixlists)
          if (filter.matches(m.isMixlist)) m,
      ],
      artists: [
        for (final a in artists)
          if (scopeIndex.artistQualifies(filter, a.id)) a,
      ],
      genres: [
        for (final g in genres)
          if (scopeIndex.genreQualifies(filter, g)) g,
      ],
      albums: [
        for (final a in albums)
          if (scopeIndex.albumQualifies(filter, a.id)) a,
      ],
      labels: [
        for (final l in labels)
          if (scopeIndex.labelQualifies(filter, l)) l,
      ],
      songs: scopedSongs,
      scopeIndex: scopeIndex,
    );
  }
}
