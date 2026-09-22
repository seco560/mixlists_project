import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_manager.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/library/csv_library_import_screen.dart';
import 'package:mixlists_project/screens/spotify_import/spotify_client_id_screen.dart';
import 'package:mixlists_project/widgets/library/library_tile.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';

class LibraryPickerScreen extends StatefulWidget {
  const LibraryPickerScreen({super.key});

  @override
  State<LibraryPickerScreen> createState() => _LibraryPickerScreenState();
}

class _LibraryPickerScreenState extends State<LibraryPickerScreen> {
  late Future<List<LibraryRecord>> _librariesFuture;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _librariesFuture = getIt<LibraryManager>().listLibraries();
  }

  void _reload() {
    setState(() {
      _librariesFuture = getIt<LibraryManager>().listLibraries();
    });
  }

  Future<void> _switchTo(LibraryRecord library) async {
    if (library.id == getIt<ActiveLibraryController>().value.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch library?'),
        content: Text('Switch the active library to "${library.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await getIt<LibraryManager>().switchActiveLibrary(
        id: library.id,
        repository: getIt<MusicLibraryRepository>(),
        controller: getIt<ActiveLibraryController>(),
      );
      if (!mounted) return;
      // Detail screens below hold ids scoped to the previous library's
      // db -- reset the stack rather than leaving them showing garbage.
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not switch library: $e')));
    }
  }

  Future<void> _rename(LibraryRecord library) async {
    final controller = TextEditingController(text: library.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename library'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    await getIt<LibraryManager>().renameLibrary(library.id, newName);
    if (!mounted) return;
    _reload();
    if (getIt<ActiveLibraryController>().value.id == library.id) {
      getIt<ActiveLibraryController>().value = getIt<ActiveLibraryController>()
          .value
          .copyWith(displayName: newName);
    }
  }

  Future<void> _delete(LibraryRecord library) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete library?'),
        content: Text(
          'This permanently deletes "${library.displayName}" and everything in it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await getIt<LibraryManager>().deleteLibrary(library.id);
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _export(LibraryRecord library) async {
    setState(() => _isBusy = true);
    try {
      final bytes = await readLibraryDatabaseBytes(library.dbFileName);
      final fileName =
          '${library.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.db';
      final savedUri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/x-sqlite3',
        dialogTitle: 'Export "${library.displayName}"',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (!mounted) return;
      if (savedUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported "${library.displayName}"')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not export library: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showImportOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.podcasts),
              title: const Text('Import from Spotify'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  QuickStylePageRoute(
                    builder: (context) => const SpotifyClientIdScreen(),
                  ),
                ).then((_) => _reload());
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Import from CSV'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  QuickStylePageRoute(
                    builder: (context) => const CsvLibraryImportScreen(),
                  ),
                ).then((_) => _reload());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Libraries')),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBusy ? null : _showImportOptions,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<LibraryRecord>>(
        future: _librariesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final libraries = snapshot.data!;
          final activeId = getIt<ActiveLibraryController>().value.id;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: libraries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final library = libraries[index];
              final isBundled = library.id == bundledLibraryId;
              return LibraryTile(
                library: library,
                isActive: library.id == activeId,
                onTap: _isBusy ? () {} : () => _switchTo(library),
                onRename: _isBusy ? null : () => _rename(library),
                onDelete: (_isBusy || isBundled)
                    ? null
                    : () => _delete(library),
                onExport: _isBusy ? null : () => _export(library),
              );
            },
          );
        },
      ),
    );
  }
}
