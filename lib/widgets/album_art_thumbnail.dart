import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AlbumArtThumbnail extends StatelessWidget {
  const AlbumArtThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.borderRadius = 5,
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
