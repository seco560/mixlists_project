/// Spotify OAuth (PKCE) authentication and Web API client for importing a
/// user's own playlists into Mixlists. Pure Dart, no Flutter plugin
/// dependencies -- platform-specific redirect capture (loopback server on
/// desktop, `flutter_web_auth_2` custom-scheme on mobile) and secure token
/// storage on mobile live in the app instead. Not used on web.
library;

export 'src/auth/auth_session.dart';
export 'src/auth/credential_storage.dart';
export 'src/auth/desktop_credential_storage.dart';
export 'src/auth/loopback_server.dart';
export 'src/auth/pkce.dart';
export 'src/auth/spotify_auth.dart';
export 'src/import/ordering.dart';
export 'src/import/row_mapper.dart';
export 'src/orchestration/playlist_fetcher.dart';
export 'src/spotify_api/artist_genre_cache.dart';
export 'src/spotify_api/html_entities.dart';
export 'src/spotify_api/me.dart';
export 'src/spotify_api/paging.dart';
export 'src/spotify_api/playlists.dart';
export 'src/spotify_api/spotify_client.dart';
