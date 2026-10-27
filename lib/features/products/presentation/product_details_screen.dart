import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/state_views.dart';
import '../../authentication/presentation/require_login.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/data/cart.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../reviews/presentation/reviews_summary_section.dart';
import '../application/product_providers.dart';
import '../data/products_repository.dart';
import 'widgets/product_card.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productDetailsProvider(productId);
    final value = ref.watch(provider);
    return Scaffold(
      body: value.hasValue
          ? _DetailsBody(details: value.requireValue)
          : Scaffold(
              appBar: AppBar(),
              body: AsyncValueView(
                value: value,
                onRetry: () => ref.invalidate(provider),
                data: (_) => const SizedBox(),
              ),
            ),
    );
  }
}

class _DetailsBody extends ConsumerStatefulWidget {
  const _DetailsBody({required this.details});

  final ProductDetails details;

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  int _quantity = 1;
  final Map<String, String> _selected = {};
  bool _adding = false;

  Product get product => widget.details.product;

  bool get _optionsComplete => product.options.keys.every(_selected.containsKey);

  Future<void> _addToCart() async {
    final s = context.s;
    if (!await ensureSignedIn(context) || !mounted) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .addItem(product.id, quantity: _quantity, options: Map.of(_selected));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(s.addedToCart),
            action: SnackBarAction(label: s.viewCart, onPressed: () => context.go(Routes.cart)),
          ),
        );
    } catch (e) {
      if (mounted) showSnack(context, s.errorMessage(e));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final details = widget.details;
    final gallery = product.gallery;
    final maxQty = product.stock != null && product.stock! > 0 && product.stock! < CartItem.quantityLimit
        ? product.stock!
        : CartItem.quantityLimit;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productDetailsProvider(product.id).future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: MediaQuery.sizeOf(context).width * 0.9,
              actions: [
                FavoriteButton(product: product, filled: true),
                const SizedBox(width: Gap.sm),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: gallery.length <= 1
                    ? AppNetworkImage(url: gallery.firstOrNull, fit: BoxFit.contain, semanticLabel: product.name)
                    : PageView(
                        children: [
                          for (final url in gallery)
                            AppNetworkImage(url: url, fit: BoxFit.contain, semanticLabel: product.name),
                        ],
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(Gap.lg),
              sliver: SliverList.list(
                children: [
                  if (product.category != null)
                    Text(
                      product.category!.name,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  const SizedBox(height: Gap.xs),
                  Text(product.name, style: context.textStyles.pageTitle),
                  if (product.subtitle != null && product.subtitle != product.category?.name)
                    Text(
                      product.subtitle!,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: Gap.sm),
                  if (details.reviews.count > 0)
                    InkWell(
                      onTap: () => context.push(Routes.reviews(product.id)),
                      child: Row(
                        children: [
                          RatingStars(rating: details.reviews.average),
                          const SizedBox(width: Gap.xs),
                          Text(
                            '${details.reviews.average.toStringAsFixed(1)} · ${s.reviewsCount(details.reviews.count)}',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Gap.md),
                  PriceTag(finalPrice: product.finalPrice, price: product.price, large: true),
                  const SizedBox(height: Gap.sm),
                  _StockLabel(product: product),
                  for (final option in product.options.entries) ...[
                    const SizedBox(height: Gap.lg),
                    Text(s.selectOption(option.key), style: theme.textTheme.titleSmall),
                    const SizedBox(height: Gap.sm),
                    Wrap(
                      spacing: Gap.sm,
                      children: [
                        for (final v in option.value)
                          ChoiceChip(
                            label: Text(v),
                            selected: _selected[option.key] == v,
                            onSelected: (_) => setState(() => _selected[option.key] = v),
                          ),
                      ],
                    ),
                  ],
                  if (product.attributes.isNotEmpty) ...[
                    const SizedBox(height: Gap.xl),
                    Text(s.details, style: context.textStyles.sectionTitle),
                    const SizedBox(height: Gap.sm),
                    Card(
                      child: Column(
                        children: [
                          for (final a in product.attributes)
                            ListTile(
                              dense: true,
                              title: Text(a.label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
                                child: Text(a.display, textAlign: TextAlign.end, style: theme.textTheme.bodyMedium),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (product.description != null) ...[
                    const SizedBox(height: Gap.xl),
                    Text(s.description, style: context.textStyles.sectionTitle),
                    const SizedBox(height: Gap.sm),
                    _ExpandableText(text: product.description!),
                  ],
                  const SizedBox(height: Gap.xl),
                  ReviewsSummarySection(productId: product.id, summary: details.reviews),
                ],
              ),
            ),
            if (details.related.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionHeader(title: s.related)),
              SliverToBoxAdapter(child: ProductCarousel(products: details.related)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.sm),
          child: Row(
            children: [
              QuantityStepper(
                value: _quantity,
                max: maxQty,
                enabled: product.inStock && !_adding,
                onChanged: (v) => setState(() => _quantity = v),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: product.inStock && _optionsComplete && !_adding ? _addToCart : null,
                  icon: _adding ? const AppSpinner() : const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(product.inStock ? s.addToCart : s.outOfStock),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final low = product.inStock && product.stock != null && product.stock! <= 5;
    final (text, color, icon) = !product.inStock
        ? (s.outOfStock, scheme.error, Icons.remove_shopping_cart_outlined)
        : low
        ? (s.onlyLeft(product.stock!), context.status.warning, Icons.inventory_2_outlined)
        : (s.inStock, context.status.success, Icons.check_circle_outline_rounded);
    return Row(
      children: [
        Icon(icon, size: IconSizes.md, color: color),
        const SizedBox(width: Gap.xs),
        Text(text, style: context.textStyles.label.copyWith(color: color)),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 280;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded || !long ? null : 6,
          overflow: _expanded || !long ? null : TextOverflow.fade,
          style: context.textStyles.bodyLong,
        ),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
          ),
      ],
    );
  }
}
