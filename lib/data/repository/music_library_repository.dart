import 'package:mixlists_project/models/entities/artist.dart';
import 'package:mixlists_project/models/entities/mixlist.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/models/view_models/album_song_appearance.dart';
import 'package:mixlists_project/models/view_models/album_summary.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/models/view_models/artist_song_appearance.dart';
import 'package:mixlists_project/models/view_models/mixlist_summary.dart';
import 'package:mixlists_project/models/view_models/mixlist_track.dart';
import 'package:mixlists_project/models/view_models/search_results.dart';
import 'package:mixlists_project/models/view_models/song_search_result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'mixlist_queries.dart';
part 'artist_queries.dart';
part 'album_queries.dart';
part 'search_queries.dart';

/// The single object screens talk to for data access. It owns any query
/// that touches more than one table -- sqflite's `db.query()` convenience
/// method only builds single-table SELECTs (it's a thin wrapper that
/// assembles `SELECT ... FROM <one table> WHERE ...`, no `join()` argument),
/// so anything needing a JOIN, a GROUP BY, or hand-written SQL for any
/// other reason goes through `db.rawQuery()` instead.
///
/// The actual query methods live in the four `part` files above (one per
/// entity the query group is centered on, as `extension`s on this class)
/// rather than in this file's class body -- they're still fully part of
/// this one class from every caller's perspective (same
/// `getIt<MusicLibraryRepository>().someMethod()` call syntax) and share
/// full access to this class's private members, since `part`/`part of`
/// files are one library. This field is the one piece of mutable state any
/// of them touch, so it stays here on the class itself (extensions can add
/// methods/getters but not fields).
class MusicLibraryRepository {
  MusicLibraryRepository(this._db);

  final Database _db;

  // This assumes SongsMixlists doesn't change during the app's lifetime,
  // which is true today (the database is read-only, seeded data). If you
  // add editing later (adding/removing a song from a mixlist), call
  // `invalidateDuplicateSongIndex()` after that write so the next read
  // recomputes it. Read/written by `MixlistQueries` in mixlist_queries.dart.
  Future<Map<int, List<MixlistSummary>>>? _duplicateSongIndexFuture;

  Future<void> close() => _db.close();
}
