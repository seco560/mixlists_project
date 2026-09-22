import 'spotify_client.dart';

/// Caches artists' comma-joined genres for a run. Simplified artist objects
/// lack `genres`, so this is the one per-artist API call the import needs.
class ArtistGenreCache {
  ArtistGenreCache(this._client);

  final SpotifyClient _client;
  final Map<String, String?> _cache = {};

  Future<String?> genresFor(String artistId) async {
    if (_cache.containsKey(artistId)) return _cache[artistId];
    final json = await _client.getJson(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
    );
    final genres = (json['genres'] as List?)?.cast<String>() ?? const [];
    final joined = genres.isEmpty ? null : genres.join(', ');
    _cache[artistId] = joined;
    return joined;
  }
}
