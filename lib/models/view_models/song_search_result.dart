import 'mixlist_summary.dart';

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

  final String artistNames;

  final List<MixlistSummary> mixlists;
}
