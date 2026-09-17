/// Used for "also appears in..." worth investigating other places
/// it can be reused.
class MixlistSummary {
  const MixlistSummary({
    required this.id,
    required this.title,
    this.dateCreated,
  });

  final int id;
  final String title;
  final String? dateCreated;
}
