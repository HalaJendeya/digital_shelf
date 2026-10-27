import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/state_views.dart';
import '../../products/data/product_query.dart';
import '../../products/presentation/widgets/paged_product_grid.dart';
import 'filter_sheet.dart';

/// API-backed search. Typing is debounced; each distinct query maps to its own
/// auto-disposed provider, so the previous request is cancelled when the query
/// changes. Filters persist across query edits.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const debounce = AppDurations.debounce;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  ProductQuery _query = const ProductQuery();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(SearchScreen.debounce, () {
      if (mounted && text.trim() != (_query.q ?? '')) {
        setState(() => _query = _query.copyWith(q: text.trim()));
      }
    });
  }

  Future<void> _openFilters() async {
    final next = await showFilterSheet(context, _query);
    if (next != null && mounted) setState(() => _query = next);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasText = (_query.q ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            _onChanged(v);
          },
          decoration: InputDecoration(
            hintText: s.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: s.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                      setState(() {});
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: Gap.sm),
          ),
        ),
        actions: [
          IconButton(
            tooltip: s.filters,
            onPressed: _openFilters,
            icon: Badge(isLabelVisible: _query.hasFilters, smallSize: 8, child: const Icon(Icons.tune_rounded)),
          ),
        ],
      ),
      body: hasText || _query.hasFilters
          ? PagedProductGrid(query: _query)
          : EmptyView(message: s.typeToSearch, icon: Icons.manage_search_rounded),
    );
  }
}
