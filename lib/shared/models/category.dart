import '../../core/utils/json.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    this.sortOrder = 0,
    this.productsCount,
  });

  factory Category.fromJson(Json json) => Category(
    id: readInt(json['id']) ?? 0,
    name: readString(json['name']) ?? '',
    icon: readString(json['icon']),
    image: readString(json['image']),
    sortOrder: readInt(json['sort_order']) ?? 0,
    productsCount: readInt(json['products_count']),
  );

  final int id;
  final String name;
  final String? icon;
  final String? image;
  final int sortOrder;
  final int? productsCount;
}
