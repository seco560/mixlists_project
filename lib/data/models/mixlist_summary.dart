/// Used for "also appears in..." worth investigating other places
/// it can be reused.
class MixlistSummary {
  const MixlistSummary({
    required this.id,
    required this.title,
    this.dateCreated,
    this.isMixlist,
  });

  final int id;
  final String title;
  final String? dateCreated;

  /// `Mixlists.is_mixlists` for this entry -- only populated by queries
  /// that need to re-scope an already-fetched summary in memory (search
  /// results, re-filtered against [MixlistFilterController] without a
  /// fresh query); null wherever the summary already came from a query
  /// scoped to a single [MixlistFilter] at the SQL level.
  final bool? isMixlist;
}
