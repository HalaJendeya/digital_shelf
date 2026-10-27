import '../../core/network/api_response.dart';

/// Accumulated pages for infinite lists.
class PagedState<T> {
  const PagedState({
    required this.items,
    required this.page,
    required this.lastPage,
    this.total = 0,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory PagedState.fromPage(Paginated<T> page) => PagedState(
    items: page.items,
    page: page.meta.page,
    lastPage: page.meta.lastPage,
    total: page.meta.total,
  );

  final List<T> items;
  final int page;
  final int lastPage;
  final int total;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => page < lastPage;

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
    Object? Function()? loadMoreError,
  }) => PagedState(
    items: items ?? this.items,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
  );

  PagedState<T> append(Paginated<T> next) => PagedState(
    items: [...items, ...next.items],
    page: next.meta.page,
    lastPage: next.meta.lastPage,
    total: next.meta.total,
  );
}
