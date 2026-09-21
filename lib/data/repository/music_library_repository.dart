import 'package:flutter/foundation.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/album_song_appearance.dart';
import 'package:mixlists_project/data/models/album_summary.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/artist_song_appearance.dart';
import 'package:mixlists_project/data/models/mixlist_scope_index.dart';
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

/// Read-only access for now; strengthen when we implement editing DB entries.
///
/// A [ChangeNotifier] purely so callers that cache derived data (e.g.
/// [DuplicateSongIndexController]) can listen for "the underlying data
/// just changed via a write path" without this repository having to know
/// who's listening -- [notifyListeners] fires from every write method
/// (currently just [MixlistQueries.setMixlistFlags]), after this
/// repository's own indefinitely-cached queries have already been
/// invalidated.
class MusicLibraryRepository extends ChangeNotifier {
  MusicLibraryRepository(this._db) : ingestion = MixlistIngestion(_db);

  Database _db;

  /// Get-or-create/dedup logic lives in `package:mixlists_core` now, shared
  /// with the Mixlists Importer CLI -- see [MixlistIngestion].
  MixlistIngestion ingestion;

  Future<List<String>>? _allGenresFuture;

  Future<List<String>>? _allLabelsFuture;

  Future<MixlistScopeIndex>? _mixlistScopeIndexFuture;

  Future<void> close() => _db.close();

  /// Swaps the live database out from under this repository -- used when
  /// switching the active library. Closes the old db, rebuilds
  /// [ingestion] against the new one (it closes over the old `_db`
  /// otherwise), and invalidates every indefinitely-cached query so the
  /// next read reflects the new library rather than stale data from the
  /// old one. [DuplicateSongIndexController] listens for the active
  /// library changing separately to reload its own cache once this has
  /// swapped the db out.
  Future<void> switchTo(Database newDb) async {
    await _db.close();
    _db = newDb;
    ingestion = MixlistIngestion(newDb);
    _allGenresFuture = null;
    _allLabelsFuture = null;
    _mixlistScopeIndexFuture = null;
  }

  /// Wraps [notifyListeners] (`@protected`, so unreachable from the
  /// `extension ... on MusicLibraryRepository` query methods that aren't
  /// actual subclasses) for those write methods to call after
  /// invalidating whatever of this repository's own caches they touched.
  void _notifyMutated() => notifyListeners();
}
