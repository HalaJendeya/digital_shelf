import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/state_views.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/presentation/require_login.dart';
import '../application/cart_controller.dart';
import '../data/cart.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final signedIn = ref.watch(isAuthenticatedProvider);
    final cart = ref.watch(cartControllerProvider);
    final hasItems = cart.value?.isEmpty == false;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.cart),
        actions: [
          if (signedIn && hasItems)
            IconButton(
              tooltip: s.clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                if (!await confirmDialog(context, s.clearCartConfirm)) return;
                try {
                  await ref.read(cartControllerProvider.notifier).clear();
                } catch (e) {
                  if (context.mounted) showSnack(context, s.errorMessage(e));
                }
              },
            ),
        ],
      ),
      body: !signedIn
          ? const LoginPrompt(icon: Icons.shopping_bag_outlined)
          : RefreshIndicator(
              onRefresh: () => ref.read(cartControllerProvider.notifier).refresh(),
              child: AsyncValueView(
                value: cart,
                onRetry: () => ref.invalidate(cartControllerProvider),
                data: (cart) => cart.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: Gap.xxl),
                          MessageView(
                            icon: Icons.shopping_bag_outlined,
                            title: s.emptyCart,
                            actionLabel: s.startShopping,
                            onAction: () => context.go(Routes.home),
                          ),
                        ],
                      )
                    : _CartContent(cart: cart),
              ),
            ),
    );
  }
}

class _CartContent extends ConsumerStatefulWidget {
  const _CartContent({required this.cart});

  final Cart cart;

  @override
  ConsumerState<_CartContent> createState() => _CartContentState();
}

class _CartContentState extends ConsumerState<_CartContent> {
  final _coupon = TextEditingController();
  final _busyItems = <int>{};
  bool _couponBusy = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {int? itemId, bool coupon = false}) async {
    setState(() {
      if (itemId != null) _busyItems.add(itemId);
      if (coupon) _couponBusy = true;
    });
    try {
      await action();
      if (coupon) _coupon.clear();
    } catch (e) {
      if (mounted) showSnack(context, context.s.errorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _busyItems.remove(itemId);
          if (coupon) _couponBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final cart = widget.cart;
    final controller = ref.read(cartControllerProvider.notifier);
    final symbol = ref.watch(currencySymbolProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              for (final item in cart.items) ...[
                _CartItemTile(
                  item: item,
                  busy: _busyItems.contains(item.id),
                  onQuantity: (q) => _run(() => controller.updateQuantity(item.id, q), itemId: item.id),
                  onRemove: () => _run(() => controller.removeItem(item.id), itemId: item.id),
                ),
                const SizedBox(height: Gap.md),
              ],
              const SizedBox(height: Gap.sm),
              if (cart.couponCode != null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.local_offer_rounded, color: theme.colorScheme.primary),
                    title: Text(s.couponApplied(cart.couponCode!)),
                    trailing: _couponBusy
                        ? const AppSpinner(size: SpinnerSize.medium)
                        : IconButton(
                            tooltip: s.removeCoupon,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => _run(controller.removeCoupon, coupon: true),
                          ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coupon,
                        enabled: !_couponBusy,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: s.couponCode,
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      child: FilledButton.tonal(
                        onPressed: _couponBusy
                            ? null
                            : () {
                                final code = _coupon.text.trim();
                                if (code.isNotEmpty) _run(() => controller.applyCoupon(code), coupon: true);
                              },
                        child: Text(s.applyCoupon),
                      ),
                    ),
                  ],
                ),
              if (cart.couponError != null)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(cart.couponError!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: Gap.lg),
              CartSummaryCard(cart: cart),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!cart.meetsMinOrder && cart.minOrder != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: Text(
                      s.minOrderNotMet(formatMoney(cart.minOrder!, symbol)),
                      textAlign: TextAlign.center,
                      style: context.textStyles.label.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: cart.meetsMinOrder ? () => context.push(Routes.checkout) : null,
                  child: Text('${s.checkout} · ${formatMoney(cart.total, symbol)}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.busy, required this.onQuantity, required this.onRemove});

  final CartItem item;
  final bool busy;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: item.productId == 0 ? null : () => context.push(Routes.product(item.productId)),
        child: Padding(
          padding: const EdgeInsets.all(Gap.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: SizedBox.fromSize(
                  size: AppSizes.cartThumb,
                  child: AppNetworkImage(url: item.image),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.itemTitle,
                          ),
                        ),
                        IconButton(
                          tooltip: s.remove,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: busy ? null : onRemove,
                        ),
                      ],
                    ),
                    if (item.options.isNotEmpty)
                      Text(
                        item.options.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    if (item.unitPrice != null)
                      PriceTag(finalPrice: item.unitPrice!, price: item.originalPrice ?? item.unitPrice!),
                    if (!item.isAvailable)
                      Text(s.itemUnavailable, style: context.textStyles.label.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: Gap.xs),
                    Row(
                      children: [
                        QuantityStepper(
                          value: item.quantity,
                          max: item.maxQuantity,
                          enabled: !busy,
                          onChanged: onQuantity,
                        ),
                        const Spacer(),
                        if (busy)
                          const AppSpinner()
                        else if (item.lineTotal != null)
                          Money(item.lineTotal!, style: context.textStyles.amount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Totals exactly as returned by the API.
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    Widget row(String label, double amount, {bool bold = false, bool negative = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? theme.textTheme.titleMedium : null)),
          Text(negative ? '−' : '', style: TextStyle(color: theme.colorScheme.primary)),
          Money(
            amount,
            style: bold
                ? context.textStyles.sectionTitle
                : negative
                ? TextStyle(color: theme.colorScheme.primary)
                : null,
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          children: [
            row(s.subtotal, cart.subtotal),
            if (cart.discount > 0) row(s.discount, cart.discount, negative: true),
            row(s.deliveryFee, cart.deliveryFee),
            const Divider(),
            row(s.total, cart.total, bold: true),
          ],
        ),
      ),
    );
  }
}
