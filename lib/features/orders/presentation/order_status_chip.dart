import 'package:flutter/material.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../data/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (order.status) {
      'delivered' => context.status.success,
      'cancelled' => scheme.error,
      'pending' => context.status.warning,
      _ => scheme.primary,
    };
    return AppTag(text: order.statusLabel ?? context.s.statusLabel(order.status), color: color);
  }
}
