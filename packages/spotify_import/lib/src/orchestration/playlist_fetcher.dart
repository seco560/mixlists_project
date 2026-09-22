import 'package:mixlists_core/mixlists_core.dart';

import '../import/ordering.dart';
import '../import/row_mapper.dart';
import '../spotify_api/artist_genre_cache.dart';
import '../spotify_api/me.dart';
import '../spotify_api/paging.dart';
import '../spotify_api/playlists.dart';
import '../spotify_api/spotify_client.dart';

/// Progress events for [SpotifyPlaylistFetcher]: the CLI's `run` fetch loop
/// as a cancelable stream a GUI screen can render.
sealed class FetchEvent {
  const FetchEvent();
}

class FetchingAccount extends FetchEvent {
  const FetchingAccount();
}

class ListingPlaylists extends FetchEvent {
  const ListingPlaylists();
}

class PlaylistsListed extends FetchEvent {
  const PlaylistsListed({
    required this.importableCount,
    required this.skippedFollowedOnly,
  });
  final int importableCount;
  final int skippedFollowedOnly;
}

class FetchingPlaylist extends FetchEvent {
  const FetchingPlaylist({
    required this.playlistName,
    required this.playlistsDone,
    required this.playlistsTotal,
  });
  final String playlistName;
  final int playlistsDone;
  final int playlistsTotal;
}

class PlaylistFetched extends FetchEvent {
  const PlaylistFetched({required this.batch});
  final PlaylistImportBatch batch;
}

class FetchComplete extends FetchEvent {
  const FetchComplete({required this.batches});
  final List<PlaylistImportBatch> batches;
}

/// Raised (not emitted) if the caller cancels via [SpotifyPlaylistFetcher.cancel]
/// while a fetch is in flight.
class FetchCancelledException implements Exception {
  const FetchCancelledException();
}

class SpotifyPlaylistFetcher {
  SpotifyPlaylistFetcher(this._client);

  final SpotifyClient _client;
  bool _cancelled = false;

  /// Signals cancellation; the in-progress fetch stops at the next
  /// between-await checkpoint (after the current in-flight HTTP call, not
  /// mid-call) and the stream closes with a [FetchCancelledException].
  void cancel() => _cancelled = true;

  void _checkCancelled() {
    if (_cancelled) throw const FetchCancelledException();
  }

  /// Fetches account info, lists importable playlists, then maps each one's
  /// tracks, ending with [FetchComplete] (empty playlists skipped). [only]
  /// limits fetching; [PlaylistsListed] still reports account-wide counts.
  Stream<FetchEvent> fetchImportableBatches({
    List<SpotifyPlaylistSummary>? only,
  }) async* {
    _checkCancelled();
    yield const FetchingAccount();
    final me = await fetchCurrentUser(_client);

    _checkCancelled();
    yield const ListingPlaylists();
    final playlistResult = await fetchImportablePlaylists(
      _client,
      currentUserId: me.id,
    );
    yield PlaylistsListed(
      importableCount: playlistResult.importable.length,
      skippedFollowedOnly: playlistResult.skippedFollowedOnly,
    );

    final genreCache = ArtistGenreCache(_client);
    final batches = <PlaylistImportBatch>[];
    final playlists = only ?? playlistResult.importable;

    for (var i = 0; i < playlists.length; i++) {
      _checkCancelled();
      final playlist = playlists[i];
      yield FetchingPlaylist(
        playlistName: playlist.name,
        playlistsDone: i,
        playlistsTotal: playlists.length,
      );

      final rawItems = await fetchAllPages(
        _client,
        Uri.parse(
          'https://api.spotify.com/v1/playlists/${playlist.id}/items?limit=50',
        ),
      );

      final rows = <MixlistCsvRow>[];
      for (final wrapper in rawItems) {
        _checkCancelled();
        if (shouldSkipPlaylistItem(wrapper)) continue;
        final item = wrapper['item'] as Map<String, Object?>;
        final album = item['album'] as Map<String, Object?>;
        final albumArtistId =
            (album['artists'] as List).cast<Map<String, Object?>>().first['id']
                as String;
        final genres = await genreCache.genresFor(albumArtistId);
        rows.add(rowFromPlaylistItem(wrapper, albumArtistGenres: genres));
      }

      if (rows.isEmpty) continue;
      final batch = PlaylistImportBatch(playlist: playlist, rows: rows);
      batches.add(batch);
      yield PlaylistFetched(batch: batch);
    }

    final ordered = sortByEarliestAddedAt(batches);
    yield FetchComplete(batches: ordered);
  }
}
