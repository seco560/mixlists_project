import 'mixlist_summary.dart';

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

  final int albumTrackNumber;
  final List<MixlistSummary> mixlists;

  final List<String> datesAdded;
}
