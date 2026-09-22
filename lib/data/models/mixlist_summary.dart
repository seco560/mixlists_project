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

  /// `Mixlists.is_mixlists`; only set by queries whose results get re-scoped
  /// in memory (search). Null when the query was already filter-scoped in SQL.
  final bool? isMixlist;
}
