import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/orders_providers.dart';
import '../data/orders_repository.dart';
import 'order_status_chip.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.orders),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AppSizes.filterBarHeight),
          child: _StatusFilterBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersControllerProvider.future),
        child: AsyncValueView(
          value: ref.watch(ordersControllerProvider),
          onRetry: () => ref.invalidate(ordersControllerProvider),
          data: (paged) => paged.items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: Gap.xxl),
                    EmptyView(message: s.noOrders, icon: Icons.receipt_long_outlined),
                  ],
                )
              : NotificationListener<ScrollEndNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < AppSizes.loadMoreThreshold) {
                      ref.read(ordersControllerProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(Gap.lg),
                    itemCount: paged.items.length + (paged.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
                    itemBuilder: (context, i) {
                      if (i >= paged.items.length) {
                        return paged.loadMoreError != null
                            ? TextButton(
                                onPressed: () => ref.read(ordersControllerProvider.notifier).loadMore(),
                                child: Text(s.retry),
                              )
                            : const LoadingView();
                      }
                      final order = paged.items[i];
                      return Card(
                        child: InkWell(
                          onTap: () => context.push(Routes.order(order.id)),
                          child: Padding(
                            padding: const EdgeInsets.all(Gap.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('#${order.number}', style: context.textStyles.sectionTitle)),
                                    OrderStatusChip(order: order),
                                  ],
                                ),
                                const SizedBox(height: Gap.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDate(order.createdAt, locale, withTime: true),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                    if (order.total != null) Money(order.total!, style: context.textStyles.amount),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

/// Status chips backed by the `status` query parameter of `GET /orders`.
class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final selected = ref.watch(orderStatusFilterProvider);
    final filter = ref.read(orderStatusFilterProvider.notifier);
    return SizedBox(
      height: AppSizes.filterBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
        children: [
          for (final status in [null, ...OrdersRepository.statuses])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Gap.sm),
              child: ChoiceChip(
                label: Text(status == null ? s.allStatuses : s.statusLabel(status)),
                selected: selected == status,
                onSelected: (_) => filter.select(status),
              ),
            ),
        ],
      ),
    );
  }
}
