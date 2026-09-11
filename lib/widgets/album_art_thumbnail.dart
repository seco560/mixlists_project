import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A small rounded album-art cover, cached over the network -- the same
/// visual treatment as `AlbumGridTile`'s cover image, sized down for use
/// where many of these are shown at once (e.g. one per song in a chart).
class AlbumArtThumbnail extends StatelessWidget {
  const AlbumArtThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 36,
    this.borderRadius = 4,
  });

  final String imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
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
    );
  }
}
