import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/orders_providers.dart';
import '../data/order.dart';
import 'order_status_chip.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final provider = orderDetailsProvider(orderId);
    final value = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(value.value == null ? s.orderDetails : '#${value.value!.number}'),
        actions: [
          IconButton(
            tooltip: s.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: value.isLoading ? null : () => ref.read(provider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(provider.notifier).refresh(),
        child: AsyncValueView(
          value: value,
          onRetry: () => ref.invalidate(provider),
          data: (order) => _OrderBody(order: order),
        ),
      ),
    );
  }
}

class _OrderBody extends ConsumerStatefulWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends ConsumerState<_OrderBody> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final s = context.s;
    if (!await confirmDialog(context, s.cancelOrderConfirm) || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(orderDetailsProvider(widget.order.id).notifier).cancel();
      if (mounted) showSnack(context, s.orderCancelled);
    } catch (e) {
      if (mounted) showSnack(context, s.errorMessage(e));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final order = widget.order;
    final locale = Localizations.localeOf(context).languageCode;
    final title = context.textStyles.sectionTitle;

    Widget amount(String label, double? value, {bool bold = false}) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.xxs),
            child: Row(
              children: [
                Expanded(child: Text(label, style: bold ? title : null)),
                Money(value, style: bold ? title : null),
              ],
            ),
          );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        Row(
          children: [
            Expanded(child: Text(formatDate(order.createdAt, locale, withTime: true))),
            OrderStatusChip(order: order),
          ],
        ),
        if (order.timeline.isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          Text(s.tracking, style: title),
          const SizedBox(height: Gap.sm),
          _Timeline(steps: order.timeline),
        ],
        if (order.items.isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          Text(s.items, style: title),
          const SizedBox(height: Gap.sm),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: SizedBox.fromSize(
                  size: AppSizes.orderThumb,
                  child: AppNetworkImage(url: item.image),
                ),
              ),
              title: Text(item.name),
              subtitle: Text(
                ['× ${item.quantity}', ...item.options.entries.map((e) => '${e.key}: ${e.value}')].join(' · '),
              ),
              trailing: item.lineTotal != null ? Money(item.lineTotal!) : null,
            ),
        ],
        const SizedBox(height: Gap.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              children: [
                amount(s.subtotal, order.subtotal),
                if ((order.discount ?? 0) > 0) amount(s.discount, order.discount),
                amount(s.deliveryFee, order.deliveryFee),
                if (order.total != null) const Divider(),
                amount(s.total, order.total, bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.lg),
        Card(
          child: Column(
            children: [
              if (order.paymentMethod != null)
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(s.payment),
                  subtitle: Text(order.paymentMethodLabel ?? s.paymentLabel(order.paymentMethod)),
                ),
              if (order.customerName != null || order.address != null)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(order.customerName ?? ''),
                  subtitle: Text([order.phone, order.address].whereType<String>().join('\n')),
                ),
              if (order.notes != null) ListTile(leading: const Icon(Icons.notes_rounded), title: Text(order.notes!)),
            ],
          ),
        ),
        if (order.canCancel) ...[
          const SizedBox(height: Gap.xl),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: _cancelling ? null : _cancel,
            icon: _cancelling ? const AppSpinner() : const Icon(Icons.cancel_outlined),
            label: Text(s.cancelOrder),
          ),
        ],
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppSizes.timelineRail,
                  child: Column(
                    children: [
                      Icon(
                        steps[i].done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: IconSizes.lg,
                        color: steps[i].done ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: AppSizes.timelineLine,
                            color: steps[i + 1].done ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Gap.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label ?? s.statusLabel(steps[i].status),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: steps[i].done ? null : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (steps[i].at != null)
                          Text(formatDate(steps[i].at, locale, withTime: true), style: theme.textTheme.bodySmall),
                        if (steps[i].note != null) Text(steps[i].note!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
