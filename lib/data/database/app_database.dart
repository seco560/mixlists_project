import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const String _dbAssetPath = 'assets/database/mixlists.db';
const String bundledLibraryDbFileName = 'bundled.db';

const int _dbVersion = 5;

/// Opens the bundled library (id `"bundled"`, the fallback library), seeding
/// it from the app asset on first run.
Future<Database> openBundledLibraryDatabase() async {
  final factory = _resolveDatabaseFactory();
  final path = await _resolveLibraryPath(bundledLibraryDbFileName);

  // Seed-once-if-missing - old assets load flow fallback
  if (!await factory.databaseExists(path)) {
    await _seedDatabaseFromAssets(factory, path);
  }

  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: _dbVersion,
      onConfigure: (db) async {},
      onCreate: (db, version) async {
        // The seeded asset may already hold data while sqflite treats it as new
        // (user_version unset); only create the schema if it's truly empty.
        final checkForData = await db.rawQuery("SELECT * FROM Mixlists;");
        if (checkForData.isEmpty) {
          await createSchemaV2(db);
          await applySchemaV3(db);
          await applySchemaV4(db);
          await applySchemaV5(db);
        }
      },
      onUpgrade: _onUpgrade,
    ),
  );
}

/// Opens or creates a user-created (Spotify/CSV import) library. No seeding
/// or re-check needed: the file is always new or created by this app.
Future<Database> openOrCreateLibraryDatabase(String dbFileName) async {
  final factory = _resolveDatabaseFactory();
  final path = await _resolveLibraryPath(dbFileName);

  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: _dbVersion,
      onConfigure: (db) async {},
      onCreate: (db, version) async {
        await createSchemaV2(db);
        await applySchemaV3(db);
        await applySchemaV4(db);
        await applySchemaV5(db);
      },
      onUpgrade: _onUpgrade,
    ),
  );
}

/// Raw sqlite bytes for exporting a library. Safe while open: no WAL mode,
/// so the file on disk is always a complete snapshot.
Future<Uint8List> readLibraryDatabaseBytes(String dbFileName) async {
  final factory = _resolveDatabaseFactory();
  final path = await _resolveLibraryPath(dbFileName);
  return factory.readDatabaseBytes(path);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await createSchemaV2Indexes(db);
  }
  if (oldVersion < 3) {
    await applySchemaV3(db);
  }
  if (oldVersion < 4) {
    await applySchemaV4(db);
  }
  if (oldVersion < 5) {
    await applySchemaV5(db);
  }
}

DatabaseFactory _resolveDatabaseFactory() {
  if (kIsWeb) {
    // Handles performance issues on mobile web
    return databaseFactoryFfiWebNoWebWorker;
  }
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}

/// On web, `sqflite_common_ffi_web` keys storage by name, not a real
/// filesystem path, so the filename alone is the "path". Natively, every
/// library lives under `<app support dir>/libraries/<dbFileName>`.
Future<String> _resolveLibraryPath(String dbFileName) async {
  if (kIsWeb) return dbFileName;
  final appDirectory = Platform.isIOS
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  return join(appDirectory.path, 'libraries', dbFileName);
}

Future<void> _seedDatabaseFromAssets(
  DatabaseFactory factory,
  String path,
) async {
  final data = await rootBundle.load(_dbAssetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await factory.writeDatabaseBytes(path, bytes);
}
