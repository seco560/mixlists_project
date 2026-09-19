import 'dart:convert';
import 'dart:io';

import 'credential_storage.dart';
import 'spotify_auth.dart';

/// Persists Spotify tokens to a per-user config file on Windows/macOS/
/// Linux. No client secret is ever stored -- PKCE is a public-client flow
/// -- so the only sensitive material here is a refresh token scoped to
/// read-only playlist access. That's proportionate to a chmod'd JSON file;
/// no OS keychain integration needed. Mobile uses a separate
/// [CredentialStorage] implementation backed by secure storage instead
/// (see the app's `lib/data/spotify/mobile_credential_storage.dart`).
class DesktopCredentialStorage implements CredentialStorage {
  DesktopCredentialStorage({this._overridePath});

  final String? _overridePath;

  File get _file => File(_overridePath ?? defaultCredentialsPath());

  static String defaultCredentialsPath() {
    final home = Platform.environment['HOME'] ?? '.';
    if (Platform.isMacOS) {
      return '$home/Library/Application Support/mixlists/spotify_credentials.json';
    }
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? home;
      return '$appData\\mixlists\\spotify_credentials.json';
    }
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
    final base = (xdgConfig != null && xdgConfig.isNotEmpty)
        ? xdgConfig
        : '$home/.config';
    return '$base/mixlists/spotify_credentials.json';
  }

  @override
  Future<SpotifyTokens?> read() async {
    if (!await _file.exists()) return null;
    final content = await _file.readAsString();
    if (content.trim().isEmpty) return null;
    return SpotifyTokens.fromJson(jsonDecode(content) as Map<String, Object?>);
  }

  @override
  Future<void> write(SpotifyTokens tokens) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(tokens.toJson()),
    );
    // Best-effort -- there's no Windows equivalent attempted here.
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', _file.path]);
    }
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
