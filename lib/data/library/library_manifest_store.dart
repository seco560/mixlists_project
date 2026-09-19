import 'dart:convert';
import 'dart:io';

import 'library_record.dart';

/// Reads/writes `libraries/manifest.json` -- the list of every library
/// this install knows about. Mirrors the JSON-file-as-store pattern
/// `spotify_import`'s `DesktopCredentialStorage` already uses, applied to
/// a list instead of a single record.
class LibraryManifestStore {
  LibraryManifestStore(this._file);

  final File _file;

  Future<List<LibraryRecord>> read() async {
    if (!await _file.exists()) return [];
    final content = await _file.readAsString();
    if (content.trim().isEmpty) return [];
    final json = jsonDecode(content) as List<Object?>;
    return json
        .map((e) => LibraryRecord.fromJson(e as Map<String, Object?>))
        .toList();
  }

  Future<void> write(List<LibraryRecord> libraries) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        libraries.map((l) => l.toJson()).toList(),
      ),
    );
  }
}
