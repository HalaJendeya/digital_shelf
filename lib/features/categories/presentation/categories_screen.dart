import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/state_views.dart';
import '../../home/data/home_repository.dart';
import 'category_icon.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.categories),
        actions: [
          IconButton(
            tooltip: s.search,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(categoriesProvider.future),
        child: AsyncValueView(
          value: ref.watch(categoriesProvider),
          onRetry: () => ref.invalidate(categoriesProvider),
          data: (categories) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.apps_rounded),
                  title: Text(s.allProducts),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.productList(title: s.allProducts)),
                ),
              ),
              const SizedBox(height: Gap.md),
              if (categories.isEmpty) EmptyView(message: s.noCategories),
              for (final c in categories) ...[
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.xs),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: CategoryIcon(category: c, size: IconSizes.lg, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(c.name, style: context.textStyles.itemTitle),
                    subtitle: c.productsCount == null ? null : Text(s.productsCount(c.productsCount!)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.productList(categoryId: c.id, title: c.name)),
                  ),
                ),
                const SizedBox(height: Gap.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
