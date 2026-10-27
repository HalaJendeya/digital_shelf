import 'package:flutter/material.dart';

import '../../../app/l10n/app_strings.dart';
import '../../search/presentation/filter_sheet.dart';
import '../data/product_query.dart';
import 'widgets/paged_product_grid.dart';

/// Listing for a category, a home section ("see all"), or all products, with
/// the same filter/sort options as search. Filters persist while on screen.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.title, this.initialQuery = const ProductQuery()});

  final String? title;
  final ProductQuery initialQuery;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductQuery _query = widget.initialQuery;

  Future<void> _openFilters() async {
    final next = await showFilterSheet(
      context,
      _query,
      showCategory: widget.initialQuery.categoryId == null,
    );
    if (next != null && mounted) setState(() => _query = next);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final active = _query != widget.initialQuery;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? s.allProducts),
        actions: [
          IconButton(
            tooltip: s.filters,
            onPressed: _openFilters,
            icon: Badge(isLabelVisible: active, smallSize: 8, child: const Icon(Icons.tune_rounded)),
          ),
        ],
      ),
      body: PagedProductGrid(query: _query),
    );
  }
}
