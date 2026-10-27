import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'status_colors.dart';

/// Short accessors: `context.colors`, `context.status`, `context.textStyles`.
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
  AppTextStyles get textStyles =>
      Theme.of(this).extension<AppTextStyles>() ??
      AppTextStyles.from(Theme.of(this).textTheme, Theme.of(this).colorScheme);
}
