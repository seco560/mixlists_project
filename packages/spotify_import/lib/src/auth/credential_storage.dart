import 'spotify_auth.dart';

/// Where [SpotifyTokens] persist between launches: a JSON file on desktop,
/// a plugin-backed store in app code on mobile (this package is plugin-free).
abstract class CredentialStorage {
  Future<SpotifyTokens?> read();
  Future<void> write(SpotifyTokens tokens);
  Future<void> clear();
}
