import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/price_text.dart';
import '../../orders/application/orders_providers.dart';
import '../../orders/data/order.dart';

/// Confirmation using the order returned by `POST /checkout`. When opened
/// without it (deep link, process restart) the order is fetched by id.
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId, this.order});

  final int orderId;
  final Order? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = this.order ?? ref.watch(orderDetailsProvider(orderId)).value;
    final s = context.s;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: IconSizes.hero, color: context.status.success),
                  const SizedBox(height: Gap.lg),
                  Text(s.orderPlaced,
                      style: context.textStyles.pageTitle),
                  const SizedBox(height: Gap.sm),
                  if (order != null) ...[
                    SelectableText(s.orderNumber(order.number), style: theme.textTheme.titleMedium),
                    if (order.statusLabel != null || order.status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.xs),
                        child: Chip(label: Text(order.statusLabel ?? s.statusLabel(order.status))),
                      ),
                    if (order.total != null) ...[
                      const SizedBox(height: Gap.sm),
                      Money(order.total!, style: theme.textTheme.titleLarge),
                    ],
                    if (order.paymentMethod != null)
                      Text(order.paymentMethodLabel ?? s.paymentLabel(order.paymentMethod), style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: Gap.xxl),
                  FilledButton.icon(
                    onPressed: () {
                      context.go(Routes.home);
                      context.push(Routes.order(orderId));
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text(s.trackOrder),
                  ),
                  const SizedBox(height: Gap.sm),
                  TextButton(onPressed: () => context.go(Routes.home), child: Text(s.continueShopping)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
