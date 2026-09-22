/// Which playlists (by `Mixlists.is_mixlists`) a screen should show/scope
/// its data to. Deliberately just this one fixed three-way split, not a
/// general tagging/categories system -- there's no need for one yet.
enum MixlistFilter { mixlistsOnly, all, nonMixlistsOnly }

extension MixlistFilterScope on MixlistFilter {
  /// In-memory twin of the repository's SQL-level `_mixlistFilterSql`, for
  /// re-scoping data already in hand (e.g. cached search results).
  bool matches(bool isMixlist) => switch (this) {
    MixlistFilter.all => true,
    MixlistFilter.mixlistsOnly => isMixlist,
    MixlistFilter.nonMixlistsOnly => !isMixlist,
  };
}
