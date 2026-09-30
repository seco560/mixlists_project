import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';

const _titleTextStyle = TextStyle(fontSize: 16, fontWeight: .bold, height: 1.2);
const _subtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: .w500,
  height: 1.2,
);
const _metaTextStyle = TextStyle(fontSize: 12, height: 1.2);

class AlbumGridTile extends StatelessWidget {
  const AlbumGridTile({
    super.key,
    required this.album,
    this.size = defaultWidth,
  });

  final AlbumOverview album;

  /// Tile (and cover art) width; narrow grids shrink it to fit two columns.
  final double size;

  static const double defaultWidth = 200;
  static const double _textAreaHeight = 66;

  static double heightFor(double size) => size + _textAreaHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(AlbumArtThumbnail.defaultRadius),
      onTap: () => openAlbum(context, album),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          AlbumArtThumbnail(imageUrl: album.coverImageURL, size: size),
          const SizedBox(height: 6),
          Text(
            album.name,
            style: _titleTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
          Text(
            album.artistName,
            style: _subtitleTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
          Text(
            album.releaseDate.split('T')[0],
            style: _metaTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ],
      ),
    );
  }
}
