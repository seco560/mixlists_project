import 'package:shared_preferences/shared_preferences.dart';

const _clientIdPrefsKey = 'spotify_client_id';

/// The user's own Spotify Developer app Client ID (bring-your-own -- see
/// the Mixlists extension plan on why: Spotify's Developer Dashboard caps
/// a shared app at 25 users in Development Mode). Not secret -- a Client
/// ID is meant to be public in a PKCE flow -- so plain `shared_preferences`
/// is fine, no secure storage needed.
class SpotifyClientIdStore {
  SpotifyClientIdStore(this._prefs);

  final SharedPreferences _prefs;

  String? read() => _prefs.getString(_clientIdPrefsKey);

  Future<void> write(String clientId) => _prefs.setString(_clientIdPrefsKey, clientId);

  Future<void> clear() => _prefs.remove(_clientIdPrefsKey);
}
