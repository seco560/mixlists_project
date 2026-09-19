import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:spotify_import/spotify_import.dart';

import 'mobile_credential_storage.dart';

/// The custom-scheme redirect URI mobile platforms use to capture the
/// OAuth redirect via `flutter_web_auth_2` (registered in
/// `AndroidManifest.xml`/`Info.plist`, and must also be registered as a
/// redirect URI on the user's own Spotify Developer app -- see
/// `SpotifyClientIdScreen`). Desktop uses `SpotifyAuth.loopbackRedirectUri`
/// instead.
final Uri mobileSpotifyRedirectUri = Uri.parse('mixlists://spotify-callback');

const String mobileSpotifyCallbackScheme = 'mixlists';

bool get isMobileSpotifyAuthPlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Picks the right [CredentialStorage] for the current platform --
/// `spotify_import` stays plugin-free, so this platform dispatch lives in
/// app code. Not supported on web (Phase 1 excludes Spotify import there).
CredentialStorage resolveCredentialStorage() {
  if (kIsWeb) {
    throw UnsupportedError('Spotify import is not supported on web yet.');
  }
  return isMobileSpotifyAuthPlatform
      ? MobileCredentialStorage()
      : DesktopCredentialStorage();
}
