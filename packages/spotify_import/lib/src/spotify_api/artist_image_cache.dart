import 'spotify_client.dart';

/// Caches artists' first image URL for a run: the one per-artist call the
/// import makes. Dev Mode artist objects no longer carry genres (or
/// popularity/followers), only name and images.
class ArtistImageCache {
  ArtistImageCache(this._client);

  final SpotifyClient _client;
  final Map<String, String?> _cache = {};

  Future<String?> imageUrlFor(String artistId) async {
    if (_cache.containsKey(artistId)) return _cache[artistId];
    final json = await _client.getJson(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
    );
    final images = (json['images'] as List?) ?? const [];
    final url = images.isEmpty
        ? null
        : (images.first as Map<String, Object?>)['url'] as String?;
    _cache[artistId] = url;
    return url;
  }
}
