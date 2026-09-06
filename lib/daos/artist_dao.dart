import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/artist.dart';

class ArtistDao {
  ArtistDao(this._db);

  final Database _db;

  static const String table = 'Artists';

  Future<List<Artist>> getAll() async {
    final rows = await _db.query(table, orderBy: 'name ASC');
    return rows.map(Artist.fromMap).toList();
  }

  Future<Artist?> getById(int id) async {
    final rows =
        await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Artist.fromMap(rows.first);
  }

  Future<int> insert(Artist artist) {
    return _db.insert(table, artist.toMap()..remove('id'));
  }

  Future<int> update(Artist artist) {
    return _db.update(
      table,
      artist.toMap(),
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}