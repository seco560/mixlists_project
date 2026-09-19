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
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/data/models/song_search_result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'mixlist_queries.dart';
part 'artist_queries.dart';
part 'album_queries.dart';
part 'song_queries.dart';
part 'search_queries.dart';

/// `SongsExtraData.explicit` is stored as text (`"true"`/`"false"`/absent).
bool? _parseExplicit(String? raw) =>
    raw == null ? null : raw.toLowerCase() == 'true';

/// Read-only access for now; strengthen when we implement editing DB entries
class MusicLibraryRepository {
  MusicLibraryRepository(this._db) : ingestion = MixlistIngestion(_db);

  Database _db;

  /// Get-or-create/dedup logic lives in `package:mixlists_core` now, shared
  /// with the Mixlists Importer CLI -- see [MixlistIngestion].
  MixlistIngestion ingestion;

  final Map<MixlistFilter, Future<Map<int, List<MixlistSummary>>>>
  _duplicateSongIndexFutures = {};

  Future<List<String>>? _allGenresFuture;

  Future<List<String>>? _allLabelsFuture;

  Future<void> close() => _db.close();

  /// Swaps the live database out from under this repository -- used when
  /// switching the active library. Closes the old db, rebuilds
  /// [ingestion] against the new one (it closes over the old `_db`
  /// otherwise), and invalidates every indefinitely-cached query so the
  /// next read reflects the new library rather than stale data from the
  /// old one.
  Future<void> switchTo(Database newDb) async {
    await _db.close();
    _db = newDb;
    ingestion = MixlistIngestion(newDb);
    _allGenresFuture = null;
    _allLabelsFuture = null;
    _duplicateSongIndexFutures.clear();
  }
}
