import 'credential_storage.dart';
import 'spotify_auth.dart';

/// Loads the stored login and refreshes it if expired, always persisting
/// the result (Spotify may rotate refresh tokens). Uses the stored Client
/// ID unless [clientIdOverride] is given.
class AuthSession {
  AuthSession(this._store, {this._clientIdOverride});

  final CredentialStorage _store;
  final String? _clientIdOverride;

  Future<SpotifyTokens> ensureValidTokens() async {
    final tokens = await _readStoredTokens();
    if (!tokens.isExpired) return tokens;
    return _refresh(tokens);
  }

  /// Refreshes unconditionally, ignoring the local expiry clock -- for
  /// when the server itself rejects a token we thought was still good
  /// (clock skew, or Spotify revoked it early).
  Future<SpotifyTokens> forceRefresh() async {
    final tokens = await _readStoredTokens();
    return _refresh(tokens);
  }

  Future<SpotifyTokens> _readStoredTokens() async {
    final tokens = await _store.read();
    if (tokens == null) {
      throw SpotifyAuthException(
        'Not authenticated yet -- run `mixlists_importer auth` first.',
      );
    }
    return tokens;
  }

  Future<SpotifyTokens> _refresh(SpotifyTokens tokens) async {
    final auth = SpotifyAuth(clientId: _clientIdOverride ?? tokens.clientId);
    final refreshed = await auth.refresh(tokens);
    await _store.write(refreshed);
    return refreshed;
  }

  /// True if a login is currently stored (may still be expired --
  /// [ensureValidTokens] handles refreshing).
  Future<bool> isLoggedIn() async => (await _store.read()) != null;

  Future<void> logout() => _store.clear();
}
