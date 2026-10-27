enum ProductSort {
  price('price'),
  newest('newest'),
  bestSelling('best_selling'),
  rating('rating'),
  name('name');

  const ProductSort(this.apiValue);
  final String apiValue;
}

/// Filters supported by `GET /stores/{slug}/products`. Value-equal so it can be
/// used as a provider family key (identical filters share one request).
class ProductQuery {
  const ProductQuery({
    this.q,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.featured = false,
    this.sort,
    this.descending = false,
  });

  final String? q;
  final int? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool inStock;
  final bool featured;
  final ProductSort? sort;
  final bool descending;

  static const perPage = 15;

  bool get hasFilters =>
      categoryId != null || minPrice != null || maxPrice != null || inStock || featured || sort != null;

  Map<String, dynamic> toQuery({required int page}) => {
    if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
    'category_id': ?categoryId,
    if (minPrice != null) 'min_price': _num(minPrice!),
    if (maxPrice != null) 'max_price': _num(maxPrice!),
    if (inStock) 'in_stock': 1,
    if (featured) 'featured': 1,
    if (sort != null) ...{'sort': sort!.apiValue, 'order': descending ? 'desc' : 'asc'},
    'page': page,
    'per_page': perPage,
  };

  ProductQuery copyWith({
    String? q,
    int? Function()? categoryId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    bool? inStock,
    bool? featured,
    ProductSort? Function()? sort,
    bool? descending,
  }) => ProductQuery(
    q: q ?? this.q,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    minPrice: minPrice != null ? minPrice() : this.minPrice,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    inStock: inStock ?? this.inStock,
    featured: featured ?? this.featured,
    sort: sort != null ? sort() : this.sort,
    descending: descending ?? this.descending,
  );

  ProductQuery clearFilters() => ProductQuery(q: q);

  static Object _num(double v) => v == v.roundToDouble() ? v.toInt() : v;

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.q == q &&
      other.categoryId == categoryId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.inStock == inStock &&
      other.featured == featured &&
      other.sort == sort &&
      other.descending == descending;

  @override
  int get hashCode =>
      Object.hash(q, categoryId, minPrice, maxPrice, inStock, featured, sort, descending);
}
