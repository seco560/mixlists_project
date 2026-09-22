import 'package:mixlists_core/mixlists_core.dart';

import '../spotify_api/playlists.dart';

/// One playlist's fetched, mapped rows, not yet written to a db.
class PlaylistImportBatch {
  PlaylistImportBatch({required this.playlist, required this.rows});

  final SpotifyPlaylistSummary playlist;
  final List<MixlistCsvRow> rows;

  /// `min(added_at)`, the proxy for playlist creation date (Spotify has none);
  /// also decides import order, which becomes `Mixlists.id` chronology.
  String get earliestAddedAt =>
      rows.map((r) => r.addedAt).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
}

/// Sorts by [PlaylistImportBatch.earliestAddedAt], the proposed import
/// order. Imperfect (duplicated playlists inherit old `added_at`s), so
/// sanity-check it once per bulk run.
List<PlaylistImportBatch> sortByEarliestAddedAt(
  List<PlaylistImportBatch> batches,
) {
  final sorted = [...batches]
    ..sort((a, b) => a.earliestAddedAt.compareTo(b.earliestAddedAt));
  return sorted;
}
