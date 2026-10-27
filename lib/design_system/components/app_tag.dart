import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_dimensions.dart';

enum TagStyle {
  /// Solid fill with light text — for badges over product images.
  solid,

  /// Tinted pill with colored text — for statuses.
  soft,
}

class AppTag extends StatelessWidget {
  const AppTag({super.key, required this.text, required this.color, this.style = TagStyle.soft});

  final String text;
  final Color color;
  final TagStyle style;

  @override
  Widget build(BuildContext context) {
    final solid = style == TagStyle.solid;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: AppOpacity.tint),
        borderRadius: BorderRadius.circular(solid ? Radii.sm : Radii.pill),
      ),
      child: Padding(
        padding: solid
            ? const EdgeInsets.symmetric(horizontal: Gap.sm - Gap.xxs, vertical: Gap.xxs)
            : const EdgeInsets.symmetric(horizontal: Gap.md - Gap.xxs, vertical: Gap.xs),
        child: Text(
          text,
          style: solid
              ? context.textStyles.tag.copyWith(color: context.status.onImage)
              : context.textStyles.label.copyWith(color: color),
        ),
      ),
    );
  }
}
