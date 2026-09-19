import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_manager.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Creates a *new* library from one or more CSV files -- each file becomes
/// one Mixlist. To add a single CSV to the currently active library
/// instead, see `AddMixlistScreen`.
class CsvLibraryImportScreen extends StatefulWidget {
  const CsvLibraryImportScreen({super.key});

  @override
  State<CsvLibraryImportScreen> createState() => _CsvLibraryImportScreenState();
}

class _CsvLibraryImportScreenState extends State<CsvLibraryImportScreen> {
  bool _isBusy = false;
  String? _status;

  Future<void> _pickAndImport() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty) return;

    setState(() {
      _isBusy = true;
      _status = 'Reading ${files.length} file(s)...';
    });

    final parsed = <({String title, List<MixlistCsvRow> rows})>[];
    try {
      for (final file in files) {
        final path = file.path;
        if (path == null) continue;
        final content = await File(path).readAsString();
        parsed.add((
          title: MixlistCsvParser.titleFromFilePath(path),
          rows: MixlistCsvParser.parse(content),
        ));
      }
    } on MixlistCsvParseException catch (e) {
      setState(() {
        _isBusy = false;
        _status = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not read CSV: $e')));
      }
      return;
    }

    if (parsed.isEmpty) {
      setState(() {
        _isBusy = false;
        _status = null;
      });
      return;
    }

    if (!mounted) return;
    final libraryName = await _promptLibraryName(parsed.length);
    if (libraryName == null || libraryName.isEmpty) {
      setState(() {
        _isBusy = false;
        _status = null;
      });
      return;
    }

    setState(() => _status = 'Creating library...');
    final manager = getIt<LibraryManager>();
    final record = await manager.registerNewLibrary(
      displayName: libraryName,
      origin: LibraryOrigin.csvImport,
    );
    final db = await openOrCreateLibraryDatabase(record.dbFileName);
    final ingestion = MixlistIngestion(db);

    var imported = 0;
    for (final p in parsed) {
      if (!mounted) break;
      setState(() => _status = 'Importing "${p.title}"...');
      try {
        await ingestion.importMixlistFromCsvRows(
          title: p.title,
          description: '',
          rows: p.rows,
        );
        imported++;
      } on MixlistTitleExistsException {
        // Two selected files derived the same title -- skip the
        // duplicate rather than aborting the whole import.
      }
    }
    await db.close();

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _status = null;
    });

    final switchNow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import complete'),
        content: Text(
          '$imported mixlist(s) imported into "$libraryName". Switch to it now?',
        ),
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
    }
    if (mounted) Navigator.pop(context);
  }

  Future<String?> _promptLibraryName(int mixlistCount) async {
    final controller = TextEditingController(text: 'Imported library');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this library'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Library name',
            helperText: '$mixlistCount mixlist(s) will be imported',
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from CSV')),
      body: Center(
        child: _isBusy
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status ?? ''),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose one or more CSV files -- each one becomes a '
                      'mixlist in a brand-new library.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose CSV File(s)'),
                      onPressed: _pickAndImport,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
