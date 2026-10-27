import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/state_views.dart';
import '../../categories/presentation/category_icon.dart';
import '../../products/data/product_query.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../../store/data/store_repository.dart';
import '../data/home_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final store = ref.watch(storeProvider).value;
    final home = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Gap.lg,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox.square(dimension: AppSizes.logoSm, child: AppNetworkImage(url: store?.logo)),
            ),
            const SizedBox(width: Gap.md),
            Expanded(child: Text(store?.name ?? '', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.favorites,
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.push(Routes.favorites),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeProvider.future),
        child: AsyncValueView(
          value: home,
          onRetry: () => ref.invalidate(homeProvider),
          data: (data) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Gap.xl),
            children: [
              const _SearchField(),
              if (data.banners.isNotEmpty) _Banners(banners: data.banners),
              if (data.categories.isNotEmpty) ...[
                SectionHeader(
                  title: s.categories,
                  onSeeAll: () => StatefulNavigationShell.maybeOf(context)?.goBranch(1),
                ),
                _CategoryStrip(categories: data.categories),
              ],
              if (data.featured.isNotEmpty) ...[
                SectionHeader(
                  title: s.featured,
                  onSeeAll: () => context.push(Routes.productList(title: s.featured, featured: true)),
                ),
                ProductCarousel(products: data.featured),
              ],
              if (data.newest.isNotEmpty) ...[
                SectionHeader(
                  title: s.newArrivals,
                  onSeeAll: () => context.push(Routes.productList(title: s.newArrivals, sort: ProductSort.newest)),
                ),
                ProductCarousel(products: data.newest),
              ],
              if (data.bestSellers.isNotEmpty) ...[
                SectionHeader(
                  title: s.bestSellers,
                  onSeeAll: () =>
                      context.push(Routes.productList(title: s.bestSellers, sort: ProductSort.bestSelling)),
                ),
                ProductCarousel(products: data.bestSellers),
              ],
              if (data.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.xxl),
                  child: EmptyView(message: s.storeEmpty, icon: Icons.menu_book_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
      child: Semantics(
        button: true,
        label: context.s.search,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.muted),
          borderRadius: BorderRadius.circular(Radii.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: () => context.push(Routes.search),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: AppSizes.fieldPaddingVertical),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      context.s.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banners extends StatefulWidget {
  const _Banners({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _controller = PageController(viewportFraction: AppSizes.bannerViewportFraction);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(BuildContext context, HomeBanner banner) {
    switch (banner.linkType) {
      case BannerLinkType.product when banner.linkId != null:
        context.push(Routes.product(banner.linkId!));
      case BannerLinkType.category when banner.linkId != null:
        context.push(Routes.productList(categoryId: banner.linkId, title: banner.linkName));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.lg),
      child: AspectRatio(
        aspectRatio: AppSizes.bannerAspectRatio,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.banners.length,
          itemBuilder: (context, i) {
            final banner = widget.banners[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
              child: Card(
                child: InkWell(
                  onTap: banner.linkType == BannerLinkType.none ? null : () => _open(context, banner),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(url: banner.image, semanticLabel: banner.title),
                      if (banner.title != null)
                        Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Gap.md),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [context.status.imageScrim.withValues(alpha: 0), context.status.imageScrim],
                              ),
                            ),
                            child: Text(
                              banner.title!,
                              style: context.textTheme.titleMedium?.copyWith(color: context.status.onImage),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: AppSizes.categoryStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: () => context.push(Routes.productList(categoryId: c.id, title: c.name)),
            child: SizedBox(
              width: AppSizes.categoryTileWidth,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: AvatarSizes.lg,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: CategoryIcon(category: c, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
