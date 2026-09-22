import 'package:flutter/material.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';

/// A small 2x2 mosaic of up to 4 album covers, Spotify-style, for a
/// playlist's leading thumbnail. Any of the 4 quadrants without an album
/// (fewer than 4 distinct albums on the playlist) falls back to
/// [AlbumArtThumbnail]'s own placeholder tile.
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
