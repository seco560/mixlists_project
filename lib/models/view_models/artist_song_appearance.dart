import 'mixlist_summary.dart';

/// One song featured by an artist, with every mixlist it turns up in --
/// the artist-detail-screen equivalent of the duplicate-song grouping in
/// `MusicLibraryRepository.duplicateSongIndex`.
class ArtistSongAppearance {
  const ArtistSongAppearance({
    required this.songId,
    required this.songName,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.mixlists,
    required this.datesAdded,
  });

  final int songId;
  final String songName;
  final String albumName;
  final String albumCoverImageURL;
  final List<MixlistSummary> mixlists;

  /// When this song was added to each mixlist in [mixlists] (same order,
  /// ascending) -- `SongsMixlists.dateAdded`, distinct from a mixlist's own
  /// creation date.
  final List<String> datesAdded;
}
