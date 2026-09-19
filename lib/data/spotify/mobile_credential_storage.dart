import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_import/spotify_import.dart';

const _tokensKey = 'spotify_tokens';

/// Mobile implementation of [CredentialStorage], backed by the platform
/// keychain/keystore via `flutter_secure_storage`. `spotify_import` stays
/// plugin-free (see its package doc comment), so this lives in app code
/// instead, alongside `DesktopCredentialStorage` which handles
/// Windows/macOS/Linux.
class MobileCredentialStorage implements CredentialStorage {
  MobileCredentialStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<SpotifyTokens?> read() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null) return null;
    return SpotifyTokens.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> write(SpotifyTokens tokens) {
    return _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _tokensKey);
}
