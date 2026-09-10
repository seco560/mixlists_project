/// Just enough to show "also appears in ..."
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
