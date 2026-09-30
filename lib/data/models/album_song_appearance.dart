import 'mixlist_summary.dart';

class AlbumSongAppearance {
  const AlbumSongAppearance({
    required this.songId,
    required this.songName,
    required this.albumTrackNumber,
    required this.mixlists,
    required this.datesAdded,
    required this.isExplicit,
    required this.artistNames,
    this.creditedArtistId,
  });

  final int songId;
  final String songName;

  final int? albumTrackNumber;
  final List<MixlistSummary> mixlists;

  /// From `SongsExtraData.explicit` -- null when Spotify never supplied
  /// the flag for this song.
  final bool? isExplicit;

  final List<String> datesAdded;

  /// `Songs.artists`, the display string.
  final String artistNames;

  /// Set when the song isn't by the album artist (compilations, splits).
  final int? creditedArtistId;
}
