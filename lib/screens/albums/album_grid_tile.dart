import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';

const _titleTextStyle = TextStyle(fontSize: 16, fontWeight: .bold, height: 1.2);
const _subtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: .w500,
  height: 1.2,
);
const _metaTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.black54,
  height: 1.2,
);

class AlbumGridTile extends StatelessWidget {
  const AlbumGridTile({super.key, required this.album});

  final AlbumOverview album;
  
  static const double width = 200;
  static const double _textAreaHeight = 66;
  static const double height = width + _textAreaHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: .start,
        children: [
          ClipRRect(
            borderRadius: .circular(4),
            child: SizedBox(
              width: width,
              height: width,
              child: CachedNetworkImage(
                imageUrl: album.coverImageURL,
                fit: .cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.album, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
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
            style: _metaTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ],
      ),
    );
  }
}
