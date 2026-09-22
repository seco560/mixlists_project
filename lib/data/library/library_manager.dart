import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../repository/music_library_repository.dart';
import 'active_library_controller.dart';
import 'library_manifest_store.dart';
import 'library_record.dart';

const _activeLibraryIdPrefsKey = 'active_library_id';
const _bundledDisplayName = 'Mixlists (Bundled)';

/// Owns the on-disk library manifest and drives switching the active
/// library: opening its database, handing it to [MusicLibraryRepository]
/// via `switchTo`, and updating both the persisted preference and
/// [ActiveLibraryController]. Registered as a getIt singleton, like the
/// app's other cross-cutting services.
class LibraryManager {
  LibraryManager(this._manifestStore, this._prefs);

  final LibraryManifestStore _manifestStore;
  final SharedPreferences _prefs;

  /// Resolves the on-disk manifest path and constructs a [LibraryManager]
  /// -- call once during app bootstrap, before `runApp`. On web (no
  /// manifest/switching support yet -- Phase 1 excludes Spotify import
  /// from web) this still constructs successfully but [bootstrap] takes
  /// a web-specific shortcut and the manifest file is never touched.
  static Future<LibraryManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      return LibraryManager(LibraryManifestStore(File('')), prefs);
    }
    final appDirectory = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    final manifestFile = File(
      p.join(appDirectory.path, 'libraries', 'manifest.json'),
    );
    return LibraryManager(LibraryManifestStore(manifestFile), prefs);
  }

  static LibraryRecord get _bundledRecord => LibraryRecord(
    id: bundledLibraryId,
    displayName: _bundledDisplayName,
    dbFileName: bundledLibraryDbFileName,
    createdAt: DateTime.now(),
    origin: LibraryOrigin.bundled,
  );

  /// First-run bootstrap or subsequent launch: ensures the bundled
  /// library exists and is registered, resolves which library should be
  /// active (falling back to bundled if the preference points at
  /// something missing/corrupt), and opens its database. Call once,
  /// before constructing [MusicLibraryRepository].
  Future<({Database database, LibraryRecord record})> bootstrap() async {
    if (kIsWeb) {
      // No manifest/switching on web yet -- just open the one bundled
      // database, as the app always has.
      return (
        database: await openBundledLibraryDatabase(),
        record: _bundledRecord,
      );
    }

    var libraries = await _manifestStore.read();
    var bundled = _find(libraries, bundledLibraryId);
    if (bundled == null) {
      bundled = _bundledRecord;
      libraries = [...libraries, bundled];
      await _manifestStore.write(libraries);
    }

    final activeId =
        _prefs.getString(_activeLibraryIdPrefsKey) ?? bundledLibraryId;
    var active = _find(libraries, activeId) ?? bundled;

    Database db;
    try {
      db = await _openLibraryDatabase(active);
    } catch (_) {
      // The active library's file is missing/corrupt -- fall back to
      // bundled rather than leaving the app unable to open at all.
      active = bundled;
      db = await _openLibraryDatabase(bundled);
    }

    await _prefs.setString(_activeLibraryIdPrefsKey, active.id);
    return (database: db, record: active);
  }

  Future<List<LibraryRecord>> listLibraries() => _manifestStore.read();

  LibraryRecord? _find(List<LibraryRecord> libraries, String id) {
    for (final l in libraries) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<Database> _openLibraryDatabase(LibraryRecord record) {
    return record.id == bundledLibraryId
        ? openBundledLibraryDatabase()
        : openOrCreateLibraryDatabase(record.dbFileName);
  }

  /// Registers a brand-new, already-populated library (written by a
  /// Spotify or CSV import) in the manifest. Does not open or switch to
  /// it -- callers decide whether to switch afterward.
  Future<LibraryRecord> registerNewLibrary({
    required String displayName,
    required LibraryOrigin origin,
  }) async {
    final id = _generateLibraryId();
    final record = LibraryRecord(
      id: id,
      displayName: displayName,
      dbFileName: '$id.db',
      createdAt: DateTime.now(),
      origin: origin,
    );
    final libraries = await _manifestStore.read();
    await _manifestStore.write([...libraries, record]);
    return record;
  }

  Future<void> renameLibrary(String id, String newDisplayName) async {
    final libraries = await _manifestStore.read();
    final updated = [
      for (final l in libraries)
        if (l.id == id) l.copyWith(displayName: newDisplayName) else l,
    ];
    await _manifestStore.write(updated);
  }

  /// Removes a library's manifest entry and deletes its database file.
  /// Refuses to delete the bundled library or the currently active one
  /// -- switch away first.
  Future<void> deleteLibrary(String id) async {
    if (id == bundledLibraryId) {
      throw StateError('The bundled library cannot be deleted.');
    }
    if (_prefs.getString(_activeLibraryIdPrefsKey) == id) {
      throw StateError(
        'Cannot delete the active library -- switch to another one first.',
      );
    }
    final libraries = await _manifestStore.read();
    final record = _find(libraries, id);
    if (record == null) return;
    await _manifestStore.write(libraries.where((l) => l.id != id).toList());
    final appDirectory = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    final file = File(
      p.join(appDirectory.path, 'libraries', record.dbFileName),
    );
    if (await file.exists()) await file.delete();
  }

  /// Opens [id]'s database, hands it to [repository] via `switchTo`, and
  /// updates the persisted active-library preference and [controller].
  Future<void> switchActiveLibrary({
    required String id,
    required MusicLibraryRepository repository,
    required ActiveLibraryController controller,
  }) async {
    final libraries = await _manifestStore.read();
    final record = _find(libraries, id);
    if (record == null) {
      throw StateError('No library registered with id "$id".');
    }
    final db = await _openLibraryDatabase(record);
    await repository.switchTo(db);
    await _prefs.setString(_activeLibraryIdPrefsKey, record.id);
    controller.value = record;
  }

  String _generateLibraryId() {
    final random = Random.secure();
    final bytes = List<int>.generate(9, (_) => random.nextInt(256));
    final token = base64UrlEncode(
      bytes,
    ).replaceAll('=', '').replaceAll('-', '').replaceAll('_', '');
    return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}$token';
  }
}
