/// Which of the six navigable entity types a [BreadcrumbEntry] stands for.
enum BreadcrumbKind { song, album, artist, mixlist, genre, label }

/// A display-only snapshot of a pushed detail screen, carried on its route's
/// [RouteSettings.arguments]. Exactly one of [entityId] (song/album/artist/
/// mixlist) or [key] (genre/label string) is set.
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

  /// Artist chips: up to 4 album covers, known at push time. Mixlist chips
  /// load theirs lazily via [MusicLibraryRepository.getMixlistCoverArt].
  final List<String?>? mosaicUrls;
}
