import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
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
    // Cap decode for performance considerations
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheDimension = (size * devicePixelRatio).round();
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
                memCacheWidth: cacheDimension,
                memCacheHeight: cacheDimension,
                // Web's HtmlImage renders black after ImageCache
                // eviction (Flutter 3.47 regression); HttpGet avoids it.
                imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
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
