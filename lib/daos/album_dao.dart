import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/album.dart';

class AlbumDao {
  AlbumDao(this._db);

  final Database _db;

  static const String table = 'Albums';

  Future<List<Album>> getAll() async {
    final rows = await _db.query(table, orderBy: 'name ASC');
    return rows.map(Album.fromMap).toList();
  }

  Future<Album?> getById(int id) async {
    final rows =
        await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Album.fromMap(rows.first);
  }

  Future<List<Album>> getByArtist(int artistId) async {
    final rows =
        await _db.query(table, where: 'artist = ?', whereArgs: [artistId]);
    return rows.map(Album.fromMap).toList();
  }

  Future<int> insert(Album album) {
    return _db.insert(table, album.toMap()..remove('id'));
  }

  Future<int> update(Album album) {
    return _db.update(
      table,
      album.toMap(),
      where: 'id = ?',
      whereArgs: [album.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}