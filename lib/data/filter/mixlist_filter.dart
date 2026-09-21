/// Which playlists (by `Mixlists.is_mixlists`) a screen should show/scope
/// its data to. Deliberately just this one fixed three-way split, not a
/// general tagging/categories system -- there's no need for one yet.
enum MixlistFilter { mixlistsOnly, all, nonMixlistsOnly }

extension MixlistFilterScope on MixlistFilter {
  /// The in-memory equivalent of the SQL-level filter (`_mixlistFilterSql`
  /// in the repository) -- for callers that already have the data in hand
  /// (e.g. re-scoping cached search results on a filter change) instead of
  /// building a query.
  bool matches(bool isMixlist) => switch (this) {
    MixlistFilter.all => true,
    MixlistFilter.mixlistsOnly => isMixlist,
    MixlistFilter.nonMixlistsOnly => !isMixlist,
  };
}
