import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mixlists_project/data/spotify/spotify_client_id_store.dart';
import 'package:mixlists_project/data/spotify/spotify_platform_auth.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/spotify_import/spotify_login_screen.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';
import 'package:spotify_import/spotify_import.dart';

/// First-run (per install) screen for Spotify import: each user brings
/// their own free Spotify Developer app / Client ID rather than sharing
/// one baked into Mixlists -- see the extension plan on why (Spotify caps
/// a shared Development Mode app at 25 users).
class SpotifyClientIdScreen extends StatefulWidget {
  const SpotifyClientIdScreen({super.key});

  @override
  State<SpotifyClientIdScreen> createState() => _SpotifyClientIdScreenState();
}

class _SpotifyClientIdScreenState extends State<SpotifyClientIdScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: getIt<SpotifyClientIdStore>().read() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _redirectUri => isMobileSpotifyAuthPlatform
      ? mobileSpotifyRedirectUri.toString()
      : SpotifyAuth(clientId: '').loopbackRedirectUri.toString();

  Future<void> _continue() async {
    final clientId = _controller.text.trim();
    if (clientId.isEmpty) return;
    await getIt<SpotifyClientIdStore>().write(clientId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      QuickStylePageRoute(builder: (context) => const SpotifyLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Spotify')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mixlists needs your own free Spotify Developer app to import '
              'your playlists -- this keeps your login entirely between you '
              'and Spotify, with no shared app or account limits.',
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Go to developer.spotify.com/dashboard and create an app.\n'
              '2. Add this Redirect URI to it:',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _redirectUri,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _redirectUri)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('3. Copy the Client ID from your new app here:'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Spotify Client ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _continue, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
