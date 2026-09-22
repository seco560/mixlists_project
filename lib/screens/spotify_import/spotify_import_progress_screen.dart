import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_manager.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/data/spotify/spotify_platform_auth.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:spotify_import/spotify_import.dart';

class SpotifyImportProgressScreen extends StatefulWidget {
  const SpotifyImportProgressScreen({super.key, required this.playlists});

  final List<SpotifyPlaylistSummary> playlists;

  @override
  State<SpotifyImportProgressScreen> createState() =>
      _SpotifyImportProgressScreenState();
}

class _SpotifyImportProgressScreenState
    extends State<SpotifyImportProgressScreen> {
  late final SpotifyPlaylistFetcher _fetcher;
  String _status = 'Starting...';
  bool _cancelled = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = AuthSession(resolveCredentialStorage());
    _fetcher = SpotifyPlaylistFetcher(SpotifyClient(session));
    _run();
  }

  Future<void> _run() async {
    try {
      await for (final event in _fetcher.fetchImportableBatches(
        only: widget.playlists,
      )) {
        if (!mounted) return;
        switch (event) {
          case FetchingAccount():
            setState(() => _status = 'Fetching account info...');
          case ListingPlaylists():
            setState(() => _status = 'Listing playlists...');
          case PlaylistsListed():
            break;
          case FetchingPlaylist(
            :final playlistName,
            :final playlistsDone,
            :final playlistsTotal,
          ):
            setState(
              () => _status =
                  'Fetching "$playlistName" ($playlistsDone/$playlistsTotal)...',
            );
          case PlaylistFetched():
            break;
          case FetchComplete(:final batches):
            await _finalize(batches);
        }
      }
    } on FetchCancelledException {
      if (mounted) setState(() => _status = 'Cancelled.');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _finalize(List<PlaylistImportBatch> batches) async {
    if (batches.isEmpty) {
      setState(() {
        _error = 'None of the selected playlists had any importable tracks.';
      });
      return;
    }

    if (!mounted) return;
    final libraryName = await _promptLibraryName();
    if (libraryName == null || libraryName.isEmpty) {
      setState(() => _status = 'Cancelled.');
      return;
    }

    setState(() => _status = 'Writing library...');
    final manager = getIt<LibraryManager>();
    final record = await manager.registerNewLibrary(
      displayName: libraryName,
      origin: LibraryOrigin.spotifyImport,
    );
    final db = await openOrCreateLibraryDatabase(record.dbFileName);
    final ingestion = MixlistIngestion(db);

    var imported = 0;
    for (final batch in batches) {
      if (!mounted) break;
      setState(() => _status = 'Importing "${batch.playlist.name}"...');
      try {
        await ingestion.importMixlistFromCsvRows(
          title: batch.playlist.name,
          description: batch.playlist.description,
          rows: batch.rows,
        );
        imported++;
      } on MixlistTitleExistsException {
        // Two selected playlists share a name -- skip the duplicate.
      }
    }
    await db.close();

    if (!mounted) return;
    setState(() {
      _done = true;
      _status =
          '$imported/${batches.length} playlist(s) imported into "$libraryName".';
    });

    final switchNow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import complete'),
        content: Text('Switch to "$libraryName" now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (switchNow == true) {
      await manager.switchActiveLibrary(
        id: record.id,
        repository: getIt<MusicLibraryRepository>(),
        controller: getIt<ActiveLibraryController>(),
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<String?> _promptLibraryName() {
    final controller = TextEditingController(text: 'My Spotify Library');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this library'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    _fetcher.cancel();
    setState(() => _cancelled = true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _done || _error != null,
      child: Scaffold(
        appBar: AppBar(title: const Text('Importing from Spotify')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ] else ...[
                  if (!_done) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status, textAlign: TextAlign.center),
                  if (!_done && !_cancelled) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
