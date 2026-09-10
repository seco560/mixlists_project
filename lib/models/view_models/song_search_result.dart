import 'mixlist_summary.dart';

/// One song matched by name in a library-wide search, with every mixlist
/// it appears in. The search equivalent of `ArtistSongAppearance` /
/// `AlbumSongAppearance`, but not pre-scoped to one artist/album -- so
/// unlike those two, it carries its own album/artist context for display.
class SongSearchResult {
  SongSearchResult({
    required this.songId,
    required this.songName,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.artistNames,
    required this.mixlists,
  });

  final int songId;
  final String songName;
  final String albumName;
  final String albumCoverImageURL;

  /// `Songs.artists` verbatim (e.g. "A, B & C") -- there's no real FK from
  /// Songs to Artists, so this is displayed as-is rather than joined.
  final String artistNames;

  final List<MixlistSummary> mixlists;
}
