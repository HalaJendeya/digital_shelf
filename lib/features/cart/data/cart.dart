import '../../../core/utils/json.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    this.image,
    this.unitPrice,
    this.lineTotal,
    this.options = const {},
    this.stock,
    this.originalPrice,
    this.isAvailable = true,
  });

  /// Backend validation caps a single line at this quantity (live-verified 422).
  static const quantityLimit = 100;

  /// Live shape: `{id, product_id, name, image, unit_price, original_price,
  /// quantity, options, line_total, stock, is_available}`. A nested `product`
  /// is still accepted as a fallback.
  factory CartItem.fromJson(Json json) {
    final product = asJson(json['product']);
    final options = asJson(json['options']);
    return CartItem(
      id: readInt(json['id']) ?? 0,
      productId: readInt(json['product_id']) ?? readInt(product['id']) ?? 0,
      name: readString(pick(json, ['name', 'product_name'])) ?? readString(product['name']) ?? '',
      quantity: readInt(json['quantity']) ?? 1,
      image: readString(pick(json, ['thumb', 'image'])) ?? readString(pick(product, ['thumb', 'image'])),
      unitPrice: readDouble(pick(json, ['unit_price', 'price', 'final_price'])) ?? readDouble(product['final_price']),
      lineTotal: readDouble(pick(json, ['line_total', 'total', 'subtotal'])),
      options: {for (final e in options.entries) e.key: e.value.toString()},
      stock: readInt(json['stock']) ?? readInt(product['stock']),
      originalPrice: readDouble(json['original_price']),
      isAvailable: readBool(json['is_available']) ?? true,
    );
  }

  /// Highest quantity the customer may request for this line.
  int get maxQuantity => stock == null || stock! <= 0
      ? CartItem.quantityLimit
      : (stock! < CartItem.quantityLimit ? stock! : CartItem.quantityLimit);

  bool get isDiscounted => originalPrice != null && unitPrice != null && originalPrice! > unitPrice!;

  final int id;
  final int productId;
  final String name;
  final int quantity;
  final String? image;
  final double? unitPrice;
  final double? lineTotal;
  final Map<String, String> options;
  final int? stock;
  final double? originalPrice;

  /// False when the product was deactivated or sold out after being added.
  final bool isAvailable;
}

/// Server-calculated cart. Every amount comes from the API; the client never
/// recomputes totals.
class Cart {
  const Cart({
    required this.items,
    required this.itemsCount,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.meetsMinOrder,
    this.couponCode,
    this.couponError,
    this.minOrder,
    this.currency,
  });

  factory Cart.fromJson(Json json) {
    final items = asJsonList(json['items']).map(CartItem.fromJson).toList();
    return Cart(
      items: items,
      itemsCount: readInt(json['items_count']) ?? items.fold<int>(0, (sum, item) => sum + item.quantity),
      subtotal: readDouble(json['subtotal']) ?? 0,
      discount: readDouble(json['discount']) ?? 0,
      deliveryFee: readDouble(json['delivery_fee']) ?? 0,
      total: readDouble(json['total']) ?? 0,
      couponCode: readString(json['coupon_code']),
      couponError: readString(json['coupon_error']),
      minOrder: readDouble(json['min_order']),
      meetsMinOrder: readBool(json['meets_min_order']) ?? true,
      currency: readString(json['currency']),
    );
  }

  static const empty = Cart(
    items: [],
    itemsCount: 0,
    subtotal: 0,
    discount: 0,
    deliveryFee: 0,
    total: 0,
    meetsMinOrder: false,
  );

  /// True when [json] looks like a cart summary (mutation responses should be).
  static bool looksLikeCart(Json json) => json.containsKey('items') || json.containsKey('total');

  final List<CartItem> items;
  final int itemsCount;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? couponCode;
  final String? couponError;
  final double? minOrder;
  final bool meetsMinOrder;
  final String? currency;

  bool get isEmpty => items.isEmpty;
}
