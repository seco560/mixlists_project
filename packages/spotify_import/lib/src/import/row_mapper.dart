import 'package:mixlists_core/mixlists_core.dart';

/// Whether a `/playlists/{id}/items` entry should be skipped: a local file,
/// a delisted track (null `item`), or a podcast episode.
bool shouldSkipPlaylistItem(Map<String, Object?> wrapper) {
  if (wrapper['is_local'] == true) return true;
  final item = wrapper['item'] as Map<String, Object?>?;
  if (item == null) return true;
  return item['track'] != true;
}

/// Builds a [MixlistCsvRow] from one `/playlists/{id}/items` entry plus the
/// primary artist's genres. Pinned to the live response shape (flat `item`,
/// no preview_url/popularity/label); the first album artist is canonical.
MixlistCsvRow rowFromPlaylistItem(
  Map<String, Object?> wrapper, {
  required String? albumArtistGenres,
}) {
  final item = wrapper['item'] as Map<String, Object?>;
  final artists = (item['artists'] as List).cast<Map<String, Object?>>();
  final album = item['album'] as Map<String, Object?>;
  final albumArtists = (album['artists'] as List).cast<Map<String, Object?>>();
  final albumArtist = albumArtists.first;
  final images = (album['images'] as List).cast<Map<String, Object?>>();
  final externalIds = item['external_ids'] as Map<String, Object?>?;

  return MixlistCsvRow(
    trackURI: item['uri'] as String,
    trackName: item['name'] as String,
    artistURIs: artists.map((a) => a['uri'] as String).join(', '),
    artistNames: artists.map((a) => a['name'] as String).join(', '),
    albumURI: album['uri'] as String?,
    albumName: album['name'] as String,
    albumArtistURI: albumArtist['uri'] as String?,
    albumArtistName: albumArtist['name'] as String,
    albumReleaseDate: album['release_date'] as String?,
    albumImageURL: images.isNotEmpty ? images.first['url'] as String? : null,
    discNumber: item['disc_number'] as int?,
    albumTrackNumber: item['track_number'] as int?,
    durationMs: item['duration_ms'] as int,
    audioPreviewURL: null, // confirmed absent from Dev Mode responses
    isExplicit: item['explicit'] as bool? ?? false,
    popularity: null, // removed from the API for Dev Mode apps
    isrc: externalIds?['isrc'] as String?,
    addedAt: wrapper['added_at'] as String,
    genres: albumArtistGenres,
    recordLabel:
        null, // removed from the API for Dev Mode apps; supplement-step only
    danceability: null,
    energy: null,
    key: null,
    loudness: null,
    mode: null,
    speechiness: null,
    acousticness: null,
    instrumentalness: null,
    liveness: null,
    valence: null,
    tempo: null,
    timeSignature: null,
  );
}
