import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';

/// Result of the file-pick step: the parsed rows plus a pre-filled title,
/// ready for the review/edit form.
class PickedMixlistCsv {
  final String suggestedTitle;
  final List<MixlistCsvRow> rows;
  final String sourceFileName;

  const PickedMixlistCsv({
    required this.suggestedTitle,
    required this.rows,
    required this.sourceFileName,
  });
}

class MixlistImportService {
  const MixlistImportService(this._repository);

  final MusicLibraryRepository _repository;

  /// Opens a native single-file picker filtered to `.csv`, reads and
  /// parses the chosen file. Returns null if the user cancels. Throws
  /// [MixlistCsvParseException] on a malformed file.
  Future<PickedMixlistCsv?> pickAndParseCsv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null || file.path == null) return null;

    final path = file.path!;
    final content = await File(path).readAsString();
    final rows = MixlistCsvParser.parse(content);
    return PickedMixlistCsv(
      suggestedTitle: MixlistCsvParser.titleFromFilePath(path),
      rows: rows,
      sourceFileName: file.name,
    );
  }

  /// Opens a second file picker and merges its rows into [current]'s,
  /// matched by track URI (see [mergeMixlistCsvRows]) -- for combining two
  /// complementary exports of the *same* mixlist (e.g. an older
  /// app-native export rich in URIs/art/ISRC with a newer Exportify-style
  /// export rich in genres/label/audio features) into one fuller row set.
  /// Returns null if the user cancels the second pick.
  Future<PickedMixlistCsv?> pickAndMergeSecondCsv(
    PickedMixlistCsv current,
  ) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null || file.path == null) return null;

    final content = await File(file.path!).readAsString();
    final secondaryRows = MixlistCsvParser.parse(content);
    return PickedMixlistCsv(
      suggestedTitle: current.suggestedTitle,
      rows: mergeMixlistCsvRows(current.rows, secondaryRows),
      sourceFileName: '${current.sourceFileName} + ${file.name}',
    );
  }

  /// Runs the proactive duplicate-title check and, if clear, performs the
  /// atomic import. Rethrows [MixlistTitleExistsException] for the caller
  /// to show as a specific error.
  Future<int> importMixlist({
    required String title,
    required String description,
    required List<MixlistCsvRow> rows,
  }) {
    return _repository.ingestion.importMixlistFromCsvRows(
      title: title,
      description: description,
      rows: rows,
    );
  }
}
