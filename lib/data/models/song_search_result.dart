import 'mixlist_summary.dart';

class SongSearchResult {
  SongSearchResult({
    required this.songId,
    required this.songName,
    required this.albumId,
    required this.albumName,
    required this.albumCoverImageURL,
    required this.artistNames,
    required this.mixlists,
    required this.isExplicit,
  });

  final int songId;
  final String songName;
  final int albumId;
  final String albumName;
  final String? albumCoverImageURL;

  final String artistNames;

  final List<MixlistSummary> mixlists;

  /// From `SongsExtraData.explicit` -- null when Spotify never supplied
  /// the flag for this song.
  final bool? isExplicit;
}
