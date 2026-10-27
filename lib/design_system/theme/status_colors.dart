import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Semantic colors outside Material's [ColorScheme]: stock/order states,
/// ratings, favorites, and text drawn over images.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.warning,
    required this.favorite,
    required this.star,
    required this.onImage,
    required this.imageScrim,
  });

  static const light = StatusColors(
    success: AppPalette.olive,
    warning: Color(0xFFC0661B),
    favorite: AppPalette.maple,
    star: Color(0xFFD49A2A),
    onImage: AppPalette.white,
    imageScrim: Color(0x8A000000),
  );

  static const dark = StatusColors(
    success: AppPalette.sage,
    warning: AppPalette.pumpkin,
    favorite: Color(0xFFF08A7A),
    star: Color(0xFFE6B651),
    onImage: AppPalette.white,
    imageScrim: Color(0x8A000000),
  );

  /// Olive green — in stock, delivered, order placed.
  final Color success;

  /// Pumpkin — low stock, pending.
  final Color warning;

  /// Maple red — favorite heart.
  final Color favorite;

  /// Golden ochre — rating stars.
  final Color star;

  /// Text/icons placed on photos and colored tags.
  final Color onImage;

  /// Bottom gradient behind text on banners.
  final Color imageScrim;

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? favorite,
    Color? star,
    Color? onImage,
    Color? imageScrim,
  }) => StatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    favorite: favorite ?? this.favorite,
    star: star ?? this.star,
    onImage: onImage ?? this.onImage,
    imageScrim: imageScrim ?? this.imageScrim,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          favorite: Color.lerp(favorite, other.favorite, t)!,
          star: Color.lerp(star, other.star, t)!,
          onImage: Color.lerp(onImage, other.onImage, t)!,
          imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
        );
}
