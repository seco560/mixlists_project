import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/playlist_cover_grid.dart';

/// One stop in the trail panel's horizontal strip: a per-kind thumbnail
/// (artwork, a cover-art mosaic, or an icon, depending on what's actually
/// available for that [BreadcrumbEntry.kind]) plus a one-line title below.
class BreadcrumbChip extends StatelessWidget {
  const BreadcrumbChip({
    super.key,
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  static const double _thumbnailSize = 56;
  static const double _width = 72;

  final BreadcrumbEntry entry;
  final bool isCurrent;
  final VoidCallback onTap;

  Widget _iconAvatar(IconData icon) => Container(
    width: _thumbnailSize,
    height: _thumbnailSize,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Icon(icon, color: Colors.grey.shade700),
  );

  Widget _thumbnail() {
    switch (entry.kind) {
      case BreadcrumbKind.song:
      case BreadcrumbKind.album:
        return AlbumArtThumbnail(
          imageUrl: entry.imageUrl,
          size: _thumbnailSize,
        );
      case BreadcrumbKind.artist:
        final mosaic = entry.mosaicUrls;
        return mosaic == null || mosaic.isEmpty
            ? _iconAvatar(Icons.person)
            : PlaylistCoverGrid(coverImageUrls: mosaic, size: _thumbnailSize);
      case BreadcrumbKind.mixlist:
        return FutureBuilder<List<String?>>(
          future: getIt<MusicLibraryRepository>().getMixlistCoverArt(
            entry.entityId!,
          ),
          builder: (context, snapshot) => PlaylistCoverGrid(
            coverImageUrls: snapshot.data ?? const [],
            size: _thumbnailSize,
          ),
        );
      case BreadcrumbKind.genre:
        return _iconAvatar(Icons.sell_outlined);
      case BreadcrumbKind.label:
        return _iconAvatar(Icons.business_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: SizedBox(
          width: _width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: isCurrent
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                padding: isCurrent ? const EdgeInsets.all(2) : EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _thumbnail(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
