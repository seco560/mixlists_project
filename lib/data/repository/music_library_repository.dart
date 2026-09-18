import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/album_song_appearance.dart';
import 'package:mixlists_project/data/models/album_summary.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/artist_song_appearance.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/models/mixlist_track.dart';
import 'package:mixlists_project/data/models/search_results.dart';
import 'package:mixlists_project/data/models/song_search_result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'mixlist_queries.dart';
part 'artist_queries.dart';
part 'album_queries.dart';
part 'search_queries.dart';

/// Read-only access for now; strengthen when we implement editing DB entries
class MusicLibraryRepository {
  MusicLibraryRepository(this._db) : ingestion = MixlistIngestion(_db);

  final Database _db;

  /// Get-or-create/dedup logic lives in `package:mixlists_core` now, shared
  /// with the Mixlists Importer CLI -- see [MixlistIngestion].
  final MixlistIngestion ingestion;

  final Map<MixlistFilter, Future<Map<int, List<MixlistSummary>>>>
  _duplicateSongIndexFutures = {};

  Future<void> close() => _db.close();
}
