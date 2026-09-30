import 'package:flutter/material.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';

/// The artist's Spotify photo (round), or their album mosaic without one.
class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({super.key, required this.artist, this.size = 48});

  final ArtistOverview artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = artist.imageURL;
    if (imageUrl != null) {
      return AlbumArtThumbnail(
        imageUrl: imageUrl,
        size: size,
        borderRadius: size / 2,
      );
    }
    return PlaylistCoverGrid(
      coverImageUrls: [for (final a in artist.albums.take(4)) a.coverImageURL],
      size: size,
    );
  }
}
