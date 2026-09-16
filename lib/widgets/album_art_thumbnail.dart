import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AlbumArtThumbnail extends StatelessWidget {
  const AlbumArtThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.borderRadius = 5,
  });

  final String? imageUrl;
  final double size;
  final double borderRadius;

  static Widget _placeholder() => Container(
    color: Colors.grey.shade300,
    child: const Icon(Icons.album, color: Colors.grey),
  );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}
