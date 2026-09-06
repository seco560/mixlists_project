import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/song_mixlist.dart';

class SongMixlistDao {
  SongMixlistDao(this._db);

  final Database _db;

  static const String table = 'SongsMixlists';

  Future<List<SongMixlist>> getForMixlist(int mixlistId) async {
    final rows = await _db.query(
      table,
      where: 'mixlist = ?',
      whereArgs: [mixlistId],
      orderBy: 'positionIndex ASC',
    );
    return rows.map(SongMixlist.fromMap).toList();
  }

  Future<int> insert(SongMixlist entry) {
    return _db.insert(table, entry.toMap()..remove('id'));
  }

  Future<int> updatePosition(int id, int newPosition) {
    return _db.update(
      table,
      {'positionIndex': newPosition},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}