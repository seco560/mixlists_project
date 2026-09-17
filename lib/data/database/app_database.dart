import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _dbAssetPath = 'assets/database/mixlists.db';
const String _dbFileName = 'mixlists.db';

const int _dbVersion = 5;

Future<Database> openAppDatabase() async {
  _initFfiIfNeeded();

  final appDirectory = Platform.isIOS
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  final path = join(appDirectory.path, _dbFileName);

  // Copy-once-if-missing: the app now writes data of its own (e.g. the
  // "Mark Mixlists" feature) that must survive a restart, which an
  // always-copy-from-assets policy would silently wipe. To pick up a
  // fresh bundled db during development, delete the app-support copy
  // (see db_asset_sync_workflow project notes) rather than relying on
  // every launch re-copying it.
  if (!await File(path).exists()) {
    await _copyDatabaseFromAssets(path);
  }

  return openDatabase(
    path,
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
  );
}

void _initFfiIfNeeded() {
  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<void> _copyDatabaseFromAssets(String destinationPath) async {
  await Directory(dirname(destinationPath)).create(recursive: true);
  final data = await rootBundle.load(_dbAssetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await File(destinationPath).writeAsBytes(bytes);
}
