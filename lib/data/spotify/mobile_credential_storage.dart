import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotify_import/spotify_import.dart';

const _tokensKey = 'spotify_tokens';

/// Mobile [CredentialStorage] via `flutter_secure_storage`; lives in the app
/// because `spotify_import` stays plugin-free.
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
