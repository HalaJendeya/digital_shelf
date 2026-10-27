import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../home/data/home_repository.dart';
import '../../products/data/product_query.dart';

/// Bottom sheet editing every filter the products endpoint supports.
/// Returns the new query, or null when dismissed.
Future<ProductQuery?> showFilterSheet(
  BuildContext context,
  ProductQuery current, {
  bool showCategory = true,
}) => showModalBottomSheet<ProductQuery>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FilterSheet(initial: current, showCategory: showCategory),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.showCategory});

  final ProductQuery initial;
  final bool showCategory;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductQuery _query = widget.initial;
  late final _min = TextEditingController(text: _fmt(widget.initial.minPrice));
  late final _max = TextEditingController(text: _fmt(widget.initial.maxPrice));
  String? _priceError;

  static String _fmt(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_min.text.trim());
    final max = double.tryParse(_max.text.trim());
    if (min != null && max != null && min > max) {
      setState(() => _priceError = context.s.invalidPriceRange);
      return;
    }
    Navigator.pop(context, _query.copyWith(minPrice: () => min, maxPrice: () => max));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final sortLabels = {
      ProductSort.price: s.sortPrice,
      ProductSort.newest: s.sortNewest,
      ProductSort.bestSelling: s.sortBestSelling,
      ProductSort.rating: s.sortRating,
      ProductSort.name: s.sortName,
    };
    final priceFormatter = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.filters, style: theme.textTheme.titleLarge),
            const SizedBox(height: Gap.lg),
            Text(s.sortBy, style: theme.textTheme.titleSmall),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                ChoiceChip(
                  label: Text(s.sortDefault),
                  selected: _query.sort == null,
                  onSelected: (_) => setState(() => _query = _query.copyWith(sort: () => null)),
                ),
                for (final entry in sortLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _query.sort == entry.key,
                    onSelected: (_) => setState(() => _query = _query.copyWith(sort: () => entry.key)),
                  ),
              ],
            ),
            if (_query.sort != null) ...[
              const SizedBox(height: Gap.sm),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(s.ascending), icon: const Icon(Icons.arrow_upward)),
                  ButtonSegment(value: true, label: Text(s.descending), icon: const Icon(Icons.arrow_downward)),
                ],
                selected: {_query.descending},
                onSelectionChanged: (v) => setState(() => _query = _query.copyWith(descending: v.first)),
              ),
            ],
            if (widget.showCategory && categories.isNotEmpty) ...[
              const SizedBox(height: Gap.lg),
              DropdownButtonFormField<int?>(
                initialValue: _query.categoryId,
                decoration: InputDecoration(labelText: s.category),
                items: [
                  DropdownMenuItem(value: null, child: Text(s.allCategories)),
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _query = _query.copyWith(categoryId: () => v)),
              ),
            ],
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: priceFormatter,
                    decoration: InputDecoration(labelText: s.minPrice),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: priceFormatter,
                    decoration: InputDecoration(labelText: s.maxPrice),
                  ),
                ),
              ],
            ),
            if (_priceError != null)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Text(_priceError!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.inStockOnly),
              value: _query.inStock,
              onChanged: (v) => setState(() => _query = _query.copyWith(inStock: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.featuredOnly),
              value: _query.featured,
              onChanged: (v) => setState(() => _query = _query.copyWith(featured: v)),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      widget.showCategory
                          ? _query.clearFilters()
                          : _query.clearFilters().copyWith(categoryId: () => widget.initial.categoryId),
                    ),
                    child: Text(s.reset),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(child: FilledButton(onPressed: _apply, child: Text(s.apply))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
