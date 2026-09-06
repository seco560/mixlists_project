import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/song.dart';

class SongDao {
  SongDao(this._db);

  final Database _db;

  static const String table = 'Songs';

  Future<List<Song>> getAll() async {
    final rows = await _db.query(table, orderBy: 'name ASC');
    return rows.map(Song.fromMap).toList();
  }

  Future<Song?> getById(int id) async {
    final rows =
        await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Song.fromMap(rows.first);
  }

  Future<List<Song>> getByAlbum(int albumId) async {
    final rows =
        await _db.query(table, where: 'album = ?', whereArgs: [albumId]);
    return rows.map(Song.fromMap).toList();
  }

  Future<int> insert(Song song) {
    return _db.insert(table, song.toMap()..remove('id'));
  }

  Future<int> update(Song song) {
    return _db.update(
      table,
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}