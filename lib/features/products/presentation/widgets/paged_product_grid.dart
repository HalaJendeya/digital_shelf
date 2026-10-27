import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/product_providers.dart';
import '../../data/product_query.dart';
import 'product_card.dart';

/// Infinite product grid for a [ProductQuery]; fetches the next page when the
/// user nears the end, one page at a time.
class PagedProductGrid extends ConsumerWidget {
  const PagedProductGrid({super.key, required this.query, this.header});

  final ProductQuery query;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productListProvider(query);
    final value = ref.watch(provider);
    final s = context.s;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(provider),
        data: (paged) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (header != null) SliverToBoxAdapter(child: header),
            if (paged.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(message: s.noProducts, icon: Icons.search_off_rounded),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(Gap.lg),
                sliver: SliverGrid.builder(
                  gridDelegate: productGridDelegate,
                  itemCount: paged.items.length,
                  itemBuilder: (context, index) {
                    if (index >= paged.items.length - 4 && paged.hasMore && !paged.isLoadingMore &&
                        paged.loadMoreError == null) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref.read(provider.notifier).loadMore(),
                      );
                    }
                    return ProductCard(product: paged.items[index]);
                  },
                ),
              ),
            if (paged.isLoadingMore)
              const SliverToBoxAdapter(child: LoadingView())
            else if (paged.loadMoreError != null)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => ref.read(provider.notifier).loadMore(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(s.retry),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
          ],
        ),
      ),
    );
  }
}
