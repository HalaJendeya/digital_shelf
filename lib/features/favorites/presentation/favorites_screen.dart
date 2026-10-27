import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/state_views.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../application/favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.favorites)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(favoritesControllerProvider.future),
        child: AsyncValueView(
          value: ref.watch(favoritesControllerProvider),
          onRetry: () => ref.invalidate(favoritesControllerProvider),
          data: (products) => products.isEmpty
              ? ListView(children: [
                  const SizedBox(height: Gap.xxl),
                  EmptyView(message: s.noFavorites, icon: Icons.favorite_border_rounded),
                ])
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(Gap.lg),
                  gridDelegate: productGridDelegate,
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCard(key: ValueKey(products[i].id), product: products[i]),
                ),
        ),
      ),
    );
  }
}
