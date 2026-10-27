import 'package:flutter/material.dart';

enum SpinnerSize {
  /// Inside buttons and list rows.
  small(18, 2),

  /// Trailing action slots.
  medium(20, 2),

  /// Full-width primary buttons.
  button(22, 2.5),

  /// Standalone page loading.
  large(28, 3);

  const SpinnerSize(this.dimension, this.strokeWidth);
  final double dimension;
  final double strokeWidth;
}

/// Fixed-size progress indicator for inline busy states.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = SpinnerSize.small});

  final SpinnerSize size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size.dimension,
    child: CircularProgressIndicator(strokeWidth: size.strokeWidth),
  );
}
