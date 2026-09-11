import 'mixlist_summary.dart';

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

  final List<String> datesAdded;
}
