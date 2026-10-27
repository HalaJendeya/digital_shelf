import 'package:flutter/material.dart';

/// Semantic text styles derived from the Material [TextTheme] and scheme, so
/// screens ask for "a section title" rather than a size and weight.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.pageTitle,
    required this.sectionTitle,
    required this.itemTitle,
    required this.amount,
    required this.amountStrong,
    required this.price,
    required this.priceLarge,
    required this.statValue,
    required this.label,
    required this.tag,
    required this.bodyLong,
  });

  factory AppTextStyles.from(TextTheme text, ColorScheme scheme) => AppTextStyles(
    pageTitle: text.headlineSmall!.copyWith(fontWeight: FontWeight.w700),
    sectionTitle: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
    itemTitle: text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
    amount: text.titleSmall!.copyWith(fontWeight: FontWeight.w700),
    amountStrong: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
    price: text.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
    priceLarge: text.headlineSmall!.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
    statValue: text.displaySmall!.copyWith(fontWeight: FontWeight.w700),
    label: text.labelMedium!.copyWith(fontWeight: FontWeight.w600),
    tag: text.labelSmall!.copyWith(fontWeight: FontWeight.w700),
    bodyLong: text.bodyMedium!.copyWith(height: 1.6),
  );

  /// Screen headings (login, product name, success).
  final TextStyle pageTitle;

  /// Section headings inside a screen.
  final TextStyle sectionTitle;

  /// Card/list item names.
  final TextStyle itemTitle;

  /// Money in lists and line totals.
  final TextStyle amount;

  /// Totals and order numbers.
  final TextStyle amountStrong;
  final TextStyle price;
  final TextStyle priceLarge;

  /// Big numeric figures (average rating).
  final TextStyle statValue;

  /// Emphasized short labels (stock state, status chip, warnings).
  final TextStyle label;

  /// Tiny badges on images (discount, out of stock).
  final TextStyle tag;

  /// Long-form reading text (descriptions).
  final TextStyle bodyLong;

  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTextStyles(
      pageTitle: l(pageTitle, other.pageTitle),
      sectionTitle: l(sectionTitle, other.sectionTitle),
      itemTitle: l(itemTitle, other.itemTitle),
      amount: l(amount, other.amount),
      amountStrong: l(amountStrong, other.amountStrong),
      price: l(price, other.price),
      priceLarge: l(priceLarge, other.priceLarge),
      statValue: l(statValue, other.statValue),
      label: l(label, other.label),
      tag: l(tag, other.tag),
      bodyLong: l(bodyLong, other.bodyLong),
    );
  }
}
