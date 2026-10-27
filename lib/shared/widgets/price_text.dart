import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../design_system/design_system.dart';
import '../../features/store/data/store_repository.dart';

final currencySymbolProvider = Provider<String>(
  (ref) => ref.watch(storeProvider.select((s) => s.value?.currencySymbol ?? '')),
);

/// Formats an amount with the store's currency symbol.
class Money extends ConsumerWidget {
  const Money(this.amount, {super.key, this.style});

  final num amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Text(formatMoney(amount, ref.watch(currencySymbolProvider)), style: style);
}

/// Final price with the original price struck through when discounted.
class PriceTag extends ConsumerWidget {
  const PriceTag({
    super.key,
    required this.finalPrice,
    required this.price,
    this.large = false,
  });

  final double finalPrice;
  final double price;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final symbol = ref.watch(currencySymbolProvider);
    final main = large ? context.textStyles.priceLarge : context.textStyles.price;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Gap.sm - Gap.xxs,
      children: [
        Text(formatMoney(finalPrice, symbol), style: main),
        if (finalPrice < price)
          Text(
            formatMoney(price, symbol),
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
