import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/import/mixlist_import_service.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';

/// Adds one mixlist to the *currently active* library. To create a whole
/// new library from one or more CSV files instead, see
/// `CsvLibraryImportScreen`.
class AddMixlistScreen extends StatefulWidget {
  const AddMixlistScreen({super.key});

  @override
  State<AddMixlistScreen> createState() => _AddMixlistScreenState();
}

class _AddMixlistScreenState extends State<AddMixlistScreen> {
  final _service = MixlistImportService(getIt<MusicLibraryRepository>());
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PickedMixlistCsv? _picked;
  bool _isBusy = false;
  bool _markAsMixlist = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isBusy = true);
    try {
      final picked = await _service.pickAndParseCsv();
      if (picked == null) {
        setState(() => _isBusy = false);
        return;
      }
      setState(() {
        _picked = picked;
        _titleController.text = picked.suggestedTitle;
        _isBusy = false;
      });
    } on MixlistCsvParseException catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not read CSV: $e')));
      }
    }
  }

  /// Merges in a second, complementary export of the same mixlist (e.g.
  /// pairing an older app-native export with a newer Exportify-style one)
  /// -- see [MixlistImportService.pickAndMergeSecondCsv].
  Future<void> _mergeSecondFile() async {
    final current = _picked;
    if (current == null) return;
    setState(() => _isBusy = true);
    try {
      final merged = await _service.pickAndMergeSecondCsv(current);
      setState(() {
        if (merged != null) _picked = merged;
        _isBusy = false;
      });
    } on MixlistCsvParseException catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not read CSV: $e')));
      }
    }
  }

  Future<void> _confirmImport() async {
    final picked = _picked;
    if (picked == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    setState(() => _isBusy = true);
    try {
      final mixlistId = await _service.importMixlist(
        title: title,
        description: _descriptionController.text.trim(),
        rows: picked.rows,
      );
      if (_markAsMixlist) {
        await getIt<MusicLibraryRepository>().setMixlistFlags({
          mixlistId: true,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } on MixlistTitleExistsException catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing mixlist: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Mixlist'),
        centerTitle: true,
      ),
      body: picked == null
          ? Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose CSV File'),
                onPressed: _isBusy ? null : _pickFile,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File: ${picked.sourceFileName} (${picked.rows.length} tracks)',
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.merge_type),
                      label: const Text('Merge in a second export (optional)'),
                      onPressed: _isBusy ? null : _mergeSecondFile,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Mixlist Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Mark as Mixlist'),
                    value: _markAsMixlist,
                    onChanged: _isBusy
                        ? null
                        : (checked) =>
                              setState(() => _markAsMixlist = checked ?? true),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isBusy ? null : _pickFile,
                        child: const Text('Choose Different File'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isBusy ? null : _confirmImport,
                        child: _isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Import Mixlist'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
