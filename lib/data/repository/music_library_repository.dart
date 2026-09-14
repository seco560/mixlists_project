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

  /// Read-only access for now; strengthen when we implement editing DB entries
class MusicLibraryRepository {
  MusicLibraryRepository(this._db);

  final Database _db;

  Future<Map<int, List<MixlistSummary>>>? _duplicateSongIndexFuture;

  Future<void> close() => _db.close();
}
