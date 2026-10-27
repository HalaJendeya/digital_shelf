import '../../core/utils/json.dart';

class ProductImage {
  const ProductImage({required this.url, this.thumb});

  factory ProductImage.fromJson(Json json) => ProductImage(
    url: readString(json['url']) ?? '',
    thumb: readString(json['thumb']),
  );

  final String url;
  final String? thumb;
}

/// Server-formatted attribute row, e.g. `{label: "عدد الصفحات", display: "460 صفحة"}`.
class ProductAttribute {
  const ProductAttribute({required this.key, required this.label, required this.display});

  factory ProductAttribute.fromJson(Json json) => ProductAttribute(
    key: readString(json['key']) ?? '',
    label: readString(json['label']) ?? readString(json['key']) ?? '',
    display: readString(json['display']) ?? readString(json['value']) ?? '',
  );

  final String key;
  final String label;
  final String display;
}

class CategoryRef {
  const CategoryRef({required this.id, required this.name, this.icon});

  factory CategoryRef.fromJson(Json json) => CategoryRef(
    id: readInt(json['id']) ?? 0,
    name: readString(json['name']) ?? '',
    icon: readString(json['icon']),
  );

  final int id;
  final String name;
  final String? icon;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.finalPrice,
    this.slug,
    this.description,
    this.salePrice,
    this.discountPercent,
    this.stock,
    this.inStock = true,
    this.image,
    this.thumb,
    this.images = const [],
    this.attributes = const [],
    this.isFeatured = false,
    this.salesCount = 0,
    this.category,
    this.rating,
    this.isFavorite = false,
    this.options = const {},
    this.createdAt,
  });

  factory Product.fromJson(Json json) {
    final price = readDouble(json['price']) ?? 0;
    return Product(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']) ?? '',
      slug: readString(json['slug']),
      description: readString(json['description']),
      price: price,
      salePrice: readDouble(json['sale_price']),
      finalPrice: readDouble(json['final_price']) ?? price,
      discountPercent: readInt(json['discount_percent']),
      stock: readInt(json['stock']),
      inStock: readBool(json['in_stock']) ?? true,
      image: readString(json['image']),
      thumb: readString(json['thumb']),
      images: asJsonList(json['images'])
          .map(ProductImage.fromJson)
          .where((i) => i.url.isNotEmpty)
          .toList(),
      attributes: asJsonList(json['attributes_display'])
          .map(ProductAttribute.fromJson)
          .where((a) => a.display.isNotEmpty)
          .toList(),
      isFeatured: readBool(json['is_featured']) ?? false,
      salesCount: readInt(json['sales_count']) ?? 0,
      category: json['category'] is Map ? CategoryRef.fromJson(asJson(json['category'])) : null,
      rating: _readRating(json['rating']),
      isFavorite: readBool(json['is_favorite']) ?? false,
      options: _readOptions(json['options']),
      createdAt: readDate(json['created_at']),
    );
  }

  final int id;
  final String name;
  final String? slug;
  final String? description;
  final double price;
  final double? salePrice;
  final double finalPrice;
  final int? discountPercent;
  final int? stock;
  final bool inStock;
  final String? image;
  final String? thumb;
  final List<ProductImage> images;
  final List<ProductAttribute> attributes;
  final bool isFeatured;
  final int salesCount;
  final CategoryRef? category;
  final double? rating;
  final bool isFavorite;

  /// Selectable options exactly as provided by the API (`{name: [values]}`).
  /// Empty for every product in this store today — the UI never invents options.
  final Map<String, List<String>> options;
  final DateTime? createdAt;

  bool get hasDiscount => finalPrice < price;

  /// Author is a store-specific attribute for book stores; shown as a subtitle.
  String? get subtitle {
    for (final a in attributes) {
      if (a.key == 'author') return a.display;
    }
    return category?.name;
  }

  List<String> get gallery {
    if (images.isNotEmpty) return images.map((i) => i.url).toList();
    return [?image];
  }

  Product copyWith({bool? isFavorite}) => Product(
    id: id,
    name: name,
    slug: slug,
    description: description,
    price: price,
    salePrice: salePrice,
    finalPrice: finalPrice,
    discountPercent: discountPercent,
    stock: stock,
    inStock: inStock,
    image: image,
    thumb: thumb,
    images: images,
    attributes: attributes,
    isFeatured: isFeatured,
    salesCount: salesCount,
    category: category,
    rating: rating,
    isFavorite: isFavorite ?? this.isFavorite,
    options: options,
    createdAt: createdAt,
  );

  static double? _readRating(Object? value) {
    if (value is Map) return readDouble(asJson(value)['average']);
    return readDouble(value);
  }

  static Map<String, List<String>> _readOptions(Object? value) {
    if (value is! Map) return const {};
    final result = <String, List<String>>{};
    value.forEach((key, values) {
      if (values is List && values.isNotEmpty) {
        result[key.toString()] = values.map((v) => v.toString()).toList();
      }
    });
    return result;
  }
}
