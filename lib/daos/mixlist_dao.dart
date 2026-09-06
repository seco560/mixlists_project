import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/mixlist.dart';

class MixlistDao {
  MixlistDao(this._db);

  final Database _db;

  static const String table = 'Mixlists';

  Future<List<Mixlist>> getAll() async {
    final rows = await _db.query(table, orderBy: 'dateCreated ASC');
    return rows.map(Mixlist.fromMap).toList();
  }

  Future<Mixlist?> getById(int id) async {
    final rows =
        await _db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Mixlist.fromMap(rows.first);
  }

  /// Normally we won't be modifying Mixlists; but in case scope widens...
  Future<int> insert(Mixlist mixlist) {
    return _db.insert(table, mixlist.toMap()..remove('id'));
  }

  Future<int> update(Mixlist mixlist) {
    return _db.update(
      table,
      mixlist.toMap(),
      where: 'id = ?',
      whereArgs: [mixlist.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}