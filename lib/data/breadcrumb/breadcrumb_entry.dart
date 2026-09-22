/// Which of the six navigable entity types a [BreadcrumbEntry] stands for.
enum BreadcrumbKind { song, album, artist, mixlist, genre, label }

/// One stop in the breadcrumb trail -- a lightweight, display-only
/// snapshot of whatever detail screen was pushed, carried on the route's
/// [RouteSettings.arguments] so [BreadcrumbNavigatorObserver] can pick it
/// up without the screen itself knowing the trail exists.
///
/// Song/album/artist/mixlist are id-keyed ([entityId]); genre/label are
/// plain strings browsed without a stable id ([key]) -- exactly one of
/// the two is ever set, matching which lookup the entry's [kind] needs.
class BreadcrumbEntry {
  const BreadcrumbEntry({
    required this.kind,
    required this.title,
    this.subtitle,
    this.entityId,
    this.key,
    this.imageUrl,
    this.mosaicUrls,
  }) : assert(
         (entityId == null) != (key == null),
         'exactly one of entityId/key must be set',
       );

  final BreadcrumbKind kind;
  final String title;
  final String? subtitle;

  /// Set for [BreadcrumbKind.song]/[.album]/[.artist]/[.mixlist].
  final int? entityId;

  /// Set for [BreadcrumbKind.genre]/[.label] -- the raw genre/label string.
  final String? key;

  /// Song (via its album cover) and album chips.
  final String? imageUrl;

  /// Artist chips -- up to 4 of the artist's own album covers, already in
  /// memory at push time (no extra query). Mixlist chips resolve their
  /// mosaic lazily instead, via [MusicLibraryRepository.getMixlistCoverArt]
  /// at render time -- cover art isn't on hand at any mixlist push site.
  final List<String?>? mosaicUrls;
}
