import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../../favorites/presentation/favorite_button.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.product(product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: product.thumb ?? product.image, semanticLabel: product.name),
                  PositionedDirectional(
                    top: Gap.xs,
                    end: Gap.xs,
                    child: FavoriteButton(product: product, filled: true),
                  ),
                  if (product.discountPercent != null && product.hasDiscount)
                    PositionedDirectional(
                      top: Gap.sm,
                      start: Gap.sm,
                      child: AppTag(
                        text: '-${product.discountPercent}%',
                        color: theme.colorScheme.error,
                        style: TagStyle.solid,
                      ),
                    ),
                  if (!product.inStock)
                    PositionedDirectional(
                      bottom: Gap.sm,
                      start: Gap.sm,
                      child: AppTag(text: s.outOfStock, color: theme.colorScheme.outline, style: TagStyle.solid),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.itemTitle,
                  ),
                  if (product.subtitle != null)
                    Text(
                      product.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: Gap.xs),
                  PriceTag(finalPrice: product.finalPrice, price: product.price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid delegate sized so cards keep a book-cover proportion on any width.
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: AppSizes.productGridMaxExtent,
  mainAxisSpacing: Gap.md,
  crossAxisSpacing: Gap.md,
  childAspectRatio: AppSizes.productCardAspectRatio,
);

class ProductCarousel extends StatelessWidget {
  const ProductCarousel({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.productCarouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
        itemBuilder: (_, i) => SizedBox(width: AppSizes.productCardWidth, child: ProductCard(product: products[i])),
      ),
    );
  }
}
