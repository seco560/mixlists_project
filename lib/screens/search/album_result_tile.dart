import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

class AlbumResultTile extends StatelessWidget {
  const AlbumResultTile({
    super.key,
    required this.album,
    required this.onTap,
    this.showArtist = true,
  });

  final AlbumOverview album;
  final VoidCallback onTap;

  /// Off where the artist is already the page's subject.
  final bool showArtist;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: AlbumArtThumbnail(imageUrl: album.coverImageURL, size: 48),
      title: Text(
        album.name,
        style: titleTextStyle,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showArtist) Text(album.artistName, style: subtitleTextStyle),
          Text(
            album.releaseDate.split('T')[0],
            style: metaTextStyle.copyWith(color: muted),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
