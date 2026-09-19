import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:mixlists_project/data/spotify/spotify_client_id_store.dart';
import 'package:mixlists_project/data/spotify/spotify_platform_auth.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/spotify_import/spotify_playlist_picker_screen.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:spotify_import/spotify_import.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyLoginScreen extends StatefulWidget {
  const SpotifyLoginScreen({super.key});

  @override
  State<SpotifyLoginScreen> createState() => _SpotifyLoginScreenState();
}

class _SpotifyLoginScreenState extends State<SpotifyLoginScreen> {
  bool _isBusy = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final clientId = getIt<SpotifyClientIdStore>().read();
      if (clientId == null || clientId.isEmpty) {
        throw StateError('No Spotify Client ID saved yet.');
      }
      final auth = SpotifyAuth(clientId: clientId);
      final tokens = isMobileSpotifyAuthPlatform
          ? await _loginMobile(auth)
          : await _loginDesktop(auth);
      await resolveCredentialStorage().write(tokens);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        QuickStylePageRoute(builder: (context) => const SpotifyPlaylistPickerScreen()),
      );
    } catch (e) {
      setState(() {
        _isBusy = false;
        _error = '$e';
      });
    }
  }

  /// Windows/macOS/Linux: a loopback HTTP server catches the redirect,
  /// same mechanism the Mixlists Importer CLI already uses.
  Future<SpotifyTokens> _loginDesktop(SpotifyAuth auth) {
    return auth.loginViaLoopback(
      onReadyToAuthorize: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
    );
  }

  /// Android/iOS: a bound loopback port isn't a reliable redirect target,
  /// so this uses `flutter_web_auth_2`'s custom-scheme capture
  /// (`mixlists://spotify-callback`, registered in the platform manifest)
  /// instead, sharing PKCE + code exchange with the desktop path via
  /// [SpotifyAuth.buildAuthorizeUrl]/[SpotifyAuth.completeLogin].
  Future<SpotifyTokens> _loginMobile(SpotifyAuth auth) async {
    final pkce = PkcePair.generate();
    final state = randomUrlSafeToken(16);
    final authorizeUrl = auth.buildAuthorizeUrl(
      redirectUri: mobileSpotifyRedirectUri,
      state: state,
      pkce: pkce,
    );

    final resultUrl = await FlutterWebAuth2.authenticate(
      url: authorizeUrl.toString(),
      callbackUrlScheme: mobileSpotifyCallbackScheme,
    );
    final redirected = Uri.parse(resultUrl);

    if (redirected.queryParameters['error'] != null) {
      throw SpotifyAuthException(
        'Spotify returned an error: ${redirected.queryParameters['error']}',
      );
    }
    if (redirected.queryParameters['state'] != state) {
      throw SpotifyAuthException(
        'OAuth state mismatch (possible CSRF) -- aborting without exchanging '
        'the code.',
      );
    }
    final code = redirected.queryParameters['code'];
    if (code == null) {
      throw SpotifyAuthException('No authorization code received.');
    }

    return auth.completeLogin(
      code: code,
      verifier: pkce.verifier,
      redirectUri: mobileSpotifyRedirectUri,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in to Spotify')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              _isBusy
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      icon: const Icon(Icons.podcasts),
                      label: const Text('Log in with Spotify'),
                      onPressed: _login,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
