import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/models/mixlist_summary.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';

/// Song id -> every mixlist it's on, for songs on 2+ mixlists under the
/// current filter (the "also on..." badge). Loaded eagerly; reloads on
/// filter change, library switch, or a repository write notification.
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

  /// The index for whichever filter is current when loading finishes. Await
  /// this for an initial load: [value] may still hold the previous filter's.
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
