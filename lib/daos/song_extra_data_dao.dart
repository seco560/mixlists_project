import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/song_extra_data.dart';

class SongExtraDataDao {
  SongExtraDataDao(this._db);

  final Database _db;

  static const String table = 'SongsExtraData';

  Future<SongExtraData?> getBySongId(int songId) async {
    final rows = await _db
        .query(table, where: 'song = ?', whereArgs: [songId], limit: 1);
    if (rows.isEmpty) return null;
    return SongExtraData.fromMap(rows.first);
  }

  Future<int> insert(SongExtraData data) {
    return _db.insert(table, data.toMap()..remove('id'));
  }

  Future<int> update(SongExtraData data) {
    return _db.update(
      table,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}