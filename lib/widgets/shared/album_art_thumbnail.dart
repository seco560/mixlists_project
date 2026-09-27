import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';

class AlbumArtThumbnail extends StatelessWidget {
  const AlbumArtThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.borderRadius = defaultRadius,
  });

  /// Shared corner radius so art reads the same on every tile.
  static const defaultRadius = 6.0;

  final String? imageUrl;
  final double size;
  final double borderRadius;

  static Widget _placeholder(BuildContext context, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(icon, color: scheme.onSurfaceVariant),
    );
  }

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
            ? _placeholder(context, Icons.album)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: cacheDimension,
                memCacheHeight: cacheDimension,
                // Web's HtmlImage renders black after ImageCache
                // eviction (Flutter 3.47 regression); HttpGet avoids it.
                imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                placeholder: (context, url) =>
                    _placeholder(context, Icons.album),
                errorWidget: (context, url, error) =>
                    _placeholder(context, Icons.broken_image),
              ),
      ),
    );
  }
}
