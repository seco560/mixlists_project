import 'html_entities.dart';
import 'paging.dart';
import 'spotify_client.dart';

class SpotifyPlaylistSummary {
  const SpotifyPlaylistSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.collaborative,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final bool collaborative;

  factory SpotifyPlaylistSummary.fromJson(Map<String, Object?> json) {
    final owner = json['owner'] as Map<String, Object?>;
    return SpotifyPlaylistSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: unescapeHtmlEntities(json['description'] as String? ?? ''),
      ownerId: owner['id'] as String,
      collaborative: json['collaborative'] as bool? ?? false,
    );
  }
}

/// The user's playlists they can read items from (owned or collaborative);
/// followed-only ones 403 in Dev Mode, so they're filtered out and counted.
Future<({List<SpotifyPlaylistSummary> importable, int skippedFollowedOnly})>
fetchImportablePlaylists(
  SpotifyClient client, {
  required String currentUserId,
}) async {
  final raw = await fetchAllPages(
    client,
    Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50'),
  );
  final all = raw.map(SpotifyPlaylistSummary.fromJson).toList();
  final importable = all
      .where((p) => p.ownerId == currentUserId || p.collaborative)
      .toList();
  return (
    importable: importable,
    skippedFollowedOnly: all.length - importable.length,
  );
}
