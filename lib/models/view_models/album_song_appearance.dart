import 'mixlist_summary.dart';

/// One song on an album, with every mixlist it turns up in -- the
/// album-detail-screen equivalent of `ArtistSongAppearance`.
class AlbumSongAppearance {
  const AlbumSongAppearance({
    required this.songId,
    required this.songName,
    required this.albumTrackNumber,
    required this.mixlists,
    required this.datesAdded,
  });

  final int songId;
  final String songName;

  /// `SongsExtraData.albumTrackNumber`.
  final int albumTrackNumber;
  final List<MixlistSummary> mixlists;

  /// When this song was added to each mixlist in [mixlists] (same order) --
  /// `SongsMixlists.dateAdded`, distinct from a mixlist's own creation date.
  final List<String> datesAdded;
}
