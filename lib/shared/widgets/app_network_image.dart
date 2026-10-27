import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Cached image with a neutral placeholder and an icon fallback for missing
/// or broken URLs (many products in this store have no image).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.menu_book_rounded,
    this.semanticLabel,
  });

  final String? url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(fallbackIcon, size: IconSizes.placeholder, color: scheme.onSurfaceVariant.withValues(alpha: AppOpacity.muted)),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        fadeInDuration: AppDurations.fast,
        placeholder: (_, _) => ColoredBox(color: scheme.surfaceContainerHighest),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
