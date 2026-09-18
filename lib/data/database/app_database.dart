import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const String _dbAssetPath = 'assets/database/mixlists.db';
const String _dbFileName = 'mixlists.db';

const int _dbVersion = 5;

Future<Database> openAppDatabase() async {
  final factory = _resolveDatabaseFactory();
  final path = kIsWeb ? _dbFileName : await _resolveNativeDatabasePath();

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
        final checkForData = await db.rawQuery("SELECT * FROM Mixlists;");
        if (checkForData.isEmpty) {
          await createSchemaV2(db);
          await applySchemaV3(db);
          await applySchemaV4(db);
          await applySchemaV5(db);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
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
      },
    ),
  );
}

DatabaseFactory _resolveDatabaseFactory() {
  if (kIsWeb) {
    return databaseFactoryFfiWeb;
  }
  if (Platform.isLinux) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}

Future<String> _resolveNativeDatabasePath() async {
  final appDirectory = Platform.isIOS
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  return join(appDirectory.path, _dbFileName);
}

Future<void> _seedDatabaseFromAssets(DatabaseFactory factory, String path) async {
  final data = await rootBundle.load(_dbAssetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await factory.writeDatabaseBytes(path, bytes);
}
