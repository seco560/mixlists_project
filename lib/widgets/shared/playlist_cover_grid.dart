import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';

/// A Spotify-style 2x2 mosaic of up to 4 album covers; empty quadrants use
/// [AlbumArtThumbnail]'s placeholder.
class PlaylistCoverGrid extends StatelessWidget {
  const PlaylistCoverGrid({
    super.key,
    required this.coverImageUrls,
    this.size = 48,
  });

  final List<String?> coverImageUrls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 2;
    Widget cell(int index) => AlbumArtThumbnail(
      imageUrl: index < coverImageUrls.length ? coverImageUrls[index] : null,
      size: cellSize,
      borderRadius: 0,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [cell(0), cell(1)]),
            Row(mainAxisSize: MainAxisSize.min, children: [cell(2), cell(3)]),
          ],
        ),
      ),
    );
  }
}
