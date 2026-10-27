import 'package:flutter/widgets.dart';

/// Spacing scale shared by every screen.
abstract final class Gap {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Clearance under a floating action button.
  static const fabClearance = 96.0;
}

abstract final class Radii {
  static const xs = 3.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 999.0;
}

abstract final class IconSizes {
  static const sm = 14.0;
  static const base = 16.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 26.0;
  static const rating = 36.0;
  static const placeholder = 40.0;
  static const message = 64.0;
  static const hero = 96.0;
}

abstract final class AvatarSizes {
  /// Radius values for [CircleAvatar].
  static const sm = 18.0;
  static const lg = 28.0;
}

/// Fixed component dimensions.
abstract final class AppSizes {
  static const buttonHeight = 52.0;
  static const buttonHeightCompact = 48.0;
  static const fieldPaddingVertical = 14.0;

  static const logoSm = 36.0;
  static const logoMd = 72.0;
  static const logoLg = 112.0;

  static const productCardWidth = 160.0;
  static const productCarouselHeight = 290.0;
  static const productGridMaxExtent = 220.0;
  static const productCardAspectRatio = 0.58;

  static const cartThumb = Size(72, 96);
  static const orderThumb = Size(44, 56);

  static const categoryStripHeight = 96.0;
  static const categoryTileWidth = 76.0;

  static const bannerAspectRatio = 2.2;
  static const bannerViewportFraction = 0.92;

  static const timelineRail = 28.0;
  static const timelineLine = 2.0;
  static const ratingBarHeight = 6.0;
  static const ratingLabelWidth = 14.0;

  static const filterBarHeight = 56.0;

  /// Remaining scroll extent at which the next page is requested.
  static const loadMoreThreshold = 300.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const debounce = Duration(milliseconds: 400);
}
