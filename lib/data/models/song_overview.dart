import 'mixlist_summary.dart';

/// A song in the same overview shape as [ArtistOverview]/[AlbumOverview]:
/// denormalized artist/album text (no `Artists` join) plus its mixlists.
class SongOverview {
  const SongOverview({
    required this.id,
    required this.name,
    required this.artistNames,
    required this.albumID,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.mixlists,
    required this.isExplicit,
  });

  final int id;
  final String name;

  /// `Albums.id` for [albumName] -- lets a song's detail screen link to
  /// its album without a separate lookup.
  final int albumID;

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

  /// Derived from [mixlists] rather than stored, so it can't drift out of sync.
  int get appearanceCount => mixlists.length;
}
