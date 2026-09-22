import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';

/// A trail stop: kind label, per-kind thumbnail (art, mosaic or icon), and
/// a title of up to three lines.
class BreadcrumbChip extends StatelessWidget {
  const BreadcrumbChip({
    super.key,
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  static const double _thumbnailSize = 56;
  static const double _width = 72;
  static const double _horizontalPadding = 4;

  /// Total horizontal footprint of one chip, padding included -- what
  /// [BreadcrumbTrailPanel] lays its grid columns out by.
  static const double outerWidth = _width + 2 * _horizontalPadding;

  static const double _titleFontSize = 11;
  static const double _titleLineHeight = 1.2;
  static const int _titleMaxLines = 3;

  final BreadcrumbEntry entry;
  final bool isCurrent;
  final VoidCallback onTap;

  String get _kindLabel => switch (entry.kind) {
    BreadcrumbKind.song => 'Song',
    BreadcrumbKind.album => 'Album',
    BreadcrumbKind.artist => 'Artist',
    BreadcrumbKind.mixlist => 'Mixlist',
    BreadcrumbKind.genre => 'Genre',
    BreadcrumbKind.label => 'Label',
  };

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
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: 8,
        ),
        child: SizedBox(
          width: _width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _kindLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: colorScheme.outline),
              ),
              const SizedBox(height: 4),
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
              // Reserve all title lines so chips in a row share
              // a height and their thumbnails line up.
              SizedBox(
                height:
                    MediaQuery.textScalerOf(context).scale(_titleFontSize) *
                    _titleLineHeight *
                    _titleMaxLines,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    entry.title,
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    strutStyle: const StrutStyle(
                      fontSize: _titleFontSize,
                      height: _titleLineHeight,
                      forceStrutHeight: true,
                    ),
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
