import 'spotify_client.dart';

/// Follows Spotify's `next` URL on cursor-paginated responses until null,
/// collecting every page's `items`.
Future<List<Map<String, Object?>>> fetchAllPages(
  SpotifyClient client,
  Uri firstPage,
) async {
  final items = <Map<String, Object?>>[];
  Uri? next = firstPage;
  while (next != null) {
    final page = await client.getJson(next);
    items.addAll((page['items'] as List).cast<Map<String, Object?>>());
    final nextUrl = page['next'] as String?;
    next = nextUrl == null ? null : Uri.parse(nextUrl);
  }
  return items;
}
