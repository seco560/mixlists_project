import 'spotify_auth.dart';

/// Where [SpotifyTokens] get persisted between app launches. Desktop and
/// mobile need different backing stores (a plain config file vs. the
/// platform keychain/keystore via a Flutter plugin), so callers depend on
/// this interface rather than a concrete implementation -- this package
/// stays plugin-free; the mobile implementation lives in app code instead.
abstract class CredentialStorage {
  Future<SpotifyTokens?> read();
  Future<void> write(SpotifyTokens tokens);
  Future<void> clear();
}
