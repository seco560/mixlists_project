import 'package:flutter/material.dart';
import 'package:mixlists_project/data/spotify/spotify_platform_auth.dart';
import 'package:mixlists_project/screens/spotify_import/spotify_import_progress_screen.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';
import 'package:spotify_import/spotify_import.dart';

typedef _ImportablePlaylists = ({
  List<SpotifyPlaylistSummary> importable,
  int skippedFollowedOnly,
});

class SpotifyPlaylistPickerScreen extends StatefulWidget {
  const SpotifyPlaylistPickerScreen({super.key});

  @override
  State<SpotifyPlaylistPickerScreen> createState() =>
      _SpotifyPlaylistPickerScreenState();
}

class _SpotifyPlaylistPickerScreenState
    extends State<SpotifyPlaylistPickerScreen> {
  late final Future<_ImportablePlaylists> _future;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ImportablePlaylists> _load() async {
    final session = AuthSession(resolveCredentialStorage());
    final client = SpotifyClient(session);
    final me = await fetchCurrentUser(client);
    final result = await fetchImportablePlaylists(client, currentUserId: me.id);
    _selected.addAll(result.importable.map((p) => p.id));
    return result;
  }

  void _startImport(List<SpotifyPlaylistSummary> all) {
    final chosen = all.where((p) => _selected.contains(p.id)).toList();
    if (chosen.isEmpty) return;
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => SpotifyImportProgressScreen(playlists: chosen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Playlists')),
      body: FutureBuilder<_ImportablePlaylists>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          return Column(
            children: [
              if (result.skippedFollowedOnly > 0)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${result.skippedFollowedOnly} followed-only playlist(s) '
                    'skipped (not owned/collaborative).',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: result.importable.isEmpty
                    ? const Center(
                        child: Text('No importable playlists found.'),
                      )
                    : ListView(
                        children: [
                          for (final playlist in result.importable)
                            CheckboxListTile(
                              value: _selected.contains(playlist.id),
                              title: Text(playlist.name),
                              subtitle: playlist.collaborative
                                  ? const Text('Collaborative')
                                  : null,
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _selected.add(playlist.id);
                                } else {
                                  _selected.remove(playlist.id);
                                }
                              }),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => _startImport(result.importable),
                  child: Text('Import Selected (${_selected.length})'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
