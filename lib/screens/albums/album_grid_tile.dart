import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';

const _titleTextStyle = TextStyle(fontSize: 16, fontWeight: .bold, height: 1.2);
const _subtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: .w500,
  height: 1.2,
);
const _metaTextStyle = TextStyle(fontSize: 12, height: 1.2);

class AlbumGridTile extends StatelessWidget {
  const AlbumGridTile({super.key, required this.album});

  final AlbumOverview album;

  static const double width = 200;
  static const double _textAreaHeight = 66;
  static const double height = width + _textAreaHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () {
        Navigator.push(
          context,
          QuickStylePageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: .start,
        children: [
          AlbumArtThumbnail(
            imageUrl: album.coverImageURL,
            size: width,
            borderRadius: 4,
          ),
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
