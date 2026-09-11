import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class AlbumResultTile extends StatelessWidget {
  const AlbumResultTile({super.key, required this.album, required this.onTap});

  final AlbumOverview album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: album.coverImageURL,
        width: 50,
        height: 50,
      ),
      title: Text(album.name, style: titleTextStyle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(album.artistName, style: subtitleTextStyle),
          Text(album.releaseDate.split('T')[0], style: metaTextStyle),
        ],
      ),
      onTap: onTap,
    );
  }
}
