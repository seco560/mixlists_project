import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/album_overview.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/widgets/album_art_thumbnail.dart';

// Text scale borrowed from ArtistDetailScreen/MixlistDetailScreen's tiles,
// shrunk one notch since a grid tile has far less width than a full-width
// ListTile: bold ~16px for the tile's identity (album title), ~14px w500
// for the subtitle (artist name), ~12px grey for meta (release date).
// Explicit `height` factors make the text block's rendered height
// predictable, since `AlbumGridTile.height` below is a hand-tuned constant
// that has to fit it.
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

  // Fixed pixel sizes, not fractions of the available width -- this is
  // what keeps the grid Finder-style (constant tile size, column count
  // changes instead of the tiles). `height` is `width` (a square cover)
  // plus a fixed allowance for the 6px gap and 3 text lines below, with a
  // little slack so a stray extra pixel of text renders as harmless blank
  // space at the bottom of the tile rather than an overflow.
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
            style: _metaTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          ),
        ],
      ),
    );
  }
}
