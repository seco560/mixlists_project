import 'mixlist_summary.dart';

/// Every song in the library, in the same "overview" shape as
/// [ArtistOverview]/[AlbumOverview]: display text for its artist(s)/album
/// (denormalized off `Songs.artists`/`Albums.name` -- no `Artists` join
/// needed), plus every mixlist it appears in.
class SongOverview {
  const SongOverview({
    required this.id,
    required this.name,
    required this.artistNames,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.mixlists,
    required this.isExplicit,
  });

  final int id;
  final String name;

  /// From `SongsExtraData.explicit` -- null when Spotify never supplied
  /// the flag for this song.
  final bool? isExplicit;

  /// Comma-joined, straight off `Songs.artists` -- same convention as
  /// `SongSearchResult.artistNames`/`MixlistTrack.artists`. Plain display
  /// text only; not clickable, so no artist id is carried here.
  final String artistNames;

  final String albumName;
  final String? albumCoverImageURL;

  final List<MixlistSummary> mixlists;

  /// Total qualifying (song, mixlist) appearances -- derived from
  /// [mixlists] rather than a second fetched field, since both numbers
  /// come from the same grouping query and a stored field could only
  /// drift out of sync with it.
  int get appearanceCount => mixlists.length;
}
