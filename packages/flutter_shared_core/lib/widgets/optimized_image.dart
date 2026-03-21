import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized cached image widget for landing pages
/// Provides automatic caching, loading states, error handling, and smooth fade-in
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? backgroundColor;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      // Smooth fade-in animation (300ms)
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Placeholder while loading - prevents layout shift
      placeholder: (context, url) => Container(
        height: height,
        width: width,
        color: backgroundColor ?? CupertinoColors.systemGrey6,
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
      // Error widget if image fails to load
      errorWidget: (context, url, error) => Container(
        height: height,
        width: width,
        color: backgroundColor ?? CupertinoColors.systemGrey6,
        child: const Center(
          child: Icon(
            CupertinoIcons.photo,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ),
      // Memory cache configuration
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      // Max cache age: 7 days
      maxHeightDiskCache: height != null ? (height! * 3).toInt() : null,
      maxWidthDiskCache: width != null ? (width! * 3).toInt() : null,
    );
  }
}
