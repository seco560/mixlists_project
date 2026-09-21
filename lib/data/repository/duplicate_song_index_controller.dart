import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';

/// Maps a song's id to every mixlist it's on, for songs on more than one
/// within the current [MixlistFilterController] filter -- the index behind
/// the "also on..." badge in [MixlistDetailScreen].
///
/// A getIt singleton like [MixlistFilterController]/[ActiveLibraryController]
/// -- screens read [ready]/[value] instead of each owning a copy of this
/// cache -- rather than a cache living inside [MusicLibraryRepository].
/// Loads once eagerly on construction, so the underlying self-join query
/// (expensive enough to be worth keeping warm) has already run by the time
/// the first mixlist is opened, and reloads whenever the filter or the
/// active library changes -- the same two signals every other screen here
/// already reloads its own data on -- or whenever [MusicLibraryRepository]
/// notifies that a write (currently only "Mark Mixlists") changed the
/// `is_mixlists` flags this index depends on.
class DuplicateSongIndexController
    extends ValueNotifier<Map<int, List<MixlistSummary>>> {
  DuplicateSongIndexController(
    this._repository,
    this._filterController,
    this._activeLibraryController,
  ) : super(const {}) {
    _future = _load();
    _filterController.addListener(_scheduleReload);
    _activeLibraryController.addListener(_scheduleReload);
    _repository.addListener(_scheduleReload);
  }

  final MusicLibraryRepository _repository;
  final MixlistFilterController _filterController;
  final ActiveLibraryController _activeLibraryController;

  late Future<Map<int, List<MixlistSummary>>> _future;

  /// Resolves with the index for whichever filter is current by the time
  /// loading finishes. Callers that need accurate data right away (e.g. a
  /// screen's own initial load) should await this rather than reading
  /// [value] directly, since [value] doesn't update until loading
  /// completes and may still hold a previous filter's data in the
  /// meantime.
  Future<Map<int, List<MixlistSummary>>> get ready => _future;

  void _scheduleReload() {
    _future = _load();
  }

  Future<Map<int, List<MixlistSummary>>> _load() async {
    final filter = _filterController.value;
    final index = await _repository.duplicateSongIndex(filter: filter);
    // Drop the result if the filter moved on again while this was in
    // flight -- a newer [_load] call already owns [value].
    if (filter == _filterController.value) value = index;
    return index;
  }

  @override
  void dispose() {
    _filterController.removeListener(_scheduleReload);
    _activeLibraryController.removeListener(_scheduleReload);
    _repository.removeListener(_scheduleReload);
    super.dispose();
  }
}
