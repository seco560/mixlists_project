import 'package:shared_preferences/shared_preferences.dart';

const _clientIdPrefsKey = 'spotify_client_id';

/// The user's own Spotify Client ID (bring-your-own). Not secret in PKCE,
/// so plain `shared_preferences` is fine.
class SpotifyClientIdStore {
  SpotifyClientIdStore(this._prefs);

  final SharedPreferences _prefs;

  String? read() => _prefs.getString(_clientIdPrefsKey);

  Future<void> write(String clientId) =>
      _prefs.setString(_clientIdPrefsKey, clientId);

  Future<void> clear() => _prefs.remove(_clientIdPrefsKey);
}
