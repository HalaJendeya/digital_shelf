import 'package:flutter/material.dart';

/// Raw autumn bookstore tones. Widgets never use these directly — they read
/// roles from [ColorScheme] or [StatusColors] so light/dark stay consistent.
abstract final class AppPalette {
  // Browns
  static const espresso = Color(0xFF1C1612);
  static const darkRoast = Color(0xFF2B211B);
  static const bark = Color(0xFF3B2414);
  static const walnut = Color(0xFF55392A);
  static const coffee = Color(0xFF6F4E37);
  static const latte = Color(0xFFD9B08C);
  static const cream = Color(0xFFEBD9C6);
  static const parchment = Color(0xFFFBF6EF);

  // Fall accents
  static const rust = Color(0xFFB5651D);
  static const pumpkin = Color(0xFFF0A868);
  static const ochre = Color(0xFF8A6A1F);
  static const gold = Color(0xFFE0C36E);
  static const brick = Color(0xFFA4372B);
  static const maple = Color(0xFFB23A2E);
  static const olive = Color(0xFF5E7A2E);
  static const sage = Color(0xFFA9C47A);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

abstract final class AppColorSchemes {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.coffee,
    onPrimary: AppPalette.white,
    primaryContainer: AppPalette.cream,
    onPrimaryContainer: AppPalette.bark,
    secondary: AppPalette.rust,
    onSecondary: AppPalette.white,
    secondaryContainer: Color(0xFFF6DCC3),
    onSecondaryContainer: Color(0xFF4A2508),
    tertiary: AppPalette.ochre,
    onTertiary: AppPalette.white,
    tertiaryContainer: Color(0xFFF1E1B0),
    onTertiaryContainer: Color(0xFF3A2C05),
    error: AppPalette.brick,
    onError: AppPalette.white,
    errorContainer: Color(0xFFF9DAD4),
    onErrorContainer: Color(0xFF410E08),
    surface: AppPalette.parchment,
    onSurface: AppPalette.darkRoast,
    surfaceContainerLowest: AppPalette.white,
    surfaceContainerLow: Color(0xFFF5EDE2),
    surfaceContainer: Color(0xFFF0E6D8),
    surfaceContainerHigh: Color(0xFFEADFCF),
    surfaceContainerHighest: Color(0xFFE4D7C5),
    onSurfaceVariant: Color(0xFF5E5045),
    outline: Color(0xFF8C7B6B),
    outlineVariant: Color(0xFFD8C8B5),
    inverseSurface: Color(0xFF3A2F27),
    onInverseSurface: Color(0xFFF7EDE3),
    inversePrimary: AppPalette.latte,
    shadow: AppPalette.black,
    scrim: AppPalette.black,
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.latte,
    onPrimary: AppPalette.bark,
    primaryContainer: AppPalette.walnut,
    onPrimaryContainer: Color(0xFFF2DCC8),
    secondary: AppPalette.pumpkin,
    onSecondary: Color(0xFF4A2508),
    secondaryContainer: Color(0xFF6B3A12),
    onSecondaryContainer: Color(0xFFF8DCC2),
    tertiary: AppPalette.gold,
    onTertiary: Color(0xFF3A2C05),
    tertiaryContainer: Color(0xFF5A4810),
    onTertiaryContainer: Color(0xFFF4E3B4),
    error: Color(0xFFF2A598),
    onError: Color(0xFF5E1810),
    errorContainer: Color(0xFF7E2A20),
    onErrorContainer: Color(0xFFF9DAD4),
    surface: AppPalette.espresso,
    onSurface: Color(0xFFEDE0D4),
    surfaceContainerLowest: Color(0xFF16110E),
    surfaceContainerLow: Color(0xFF241D18),
    surfaceContainer: Color(0xFF2A221C),
    surfaceContainerHigh: Color(0xFF332A23),
    surfaceContainerHighest: Color(0xFF3D332B),
    onSurfaceVariant: Color(0xFFD2C2B2),
    outline: Color(0xFF9C8B7B),
    outlineVariant: Color(0xFF4E4238),
    inverseSurface: Color(0xFFEDE0D4),
    onInverseSurface: AppPalette.darkRoast,
    inversePrimary: AppPalette.coffee,
    shadow: AppPalette.black,
    scrim: AppPalette.black,
  );
}

/// Alpha levels for tints and overlays.
abstract final class AppOpacity {
  static const tint = 0.12;
  static const subtle = 0.5;
  static const muted = 0.6;
  static const strong = 0.7;
  static const overlay = 0.85;
}
