import '../../../core/utils/json.dart';

class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    this.productId,
    this.image,
    this.unitPrice,
    this.lineTotal,
    this.options = const {},
  });

  factory OrderItem.fromJson(Json json) {
    final product = asJson(json['product']);
    final options = asJson(json['options']);
    return OrderItem(
      productId: readInt(json['product_id']) ?? readInt(product['id']),
      name: readString(pick(json, ['name', 'product_name'])) ?? readString(product['name']) ?? '',
      quantity: readInt(json['quantity']) ?? 1,
      image: readString(pick(json, ['thumb', 'image'])) ?? readString(pick(product, ['thumb', 'image'])),
      unitPrice: readDouble(pick(json, ['unit_price', 'price'])),
      lineTotal: readDouble(pick(json, ['line_total', 'total', 'subtotal'])),
      options: {for (final e in options.entries) e.key: e.value.toString()},
    );
  }

  final int? productId;
  final String name;
  final int quantity;
  final String? image;
  final double? unitPrice;
  final double? lineTotal;
  final Map<String, String> options;
}

/// One stage of the backend-provided tracking timeline.
class TimelineStep {
  const TimelineStep({required this.status, this.label, this.at, this.note, required this.done});

  factory TimelineStep.fromJson(Json json) {
    final at = readDate(pick(json, ['at', 'date', 'time', 'reached_at', 'created_at']));
    return TimelineStep(
      status: readString(pick(json, ['status', 'key'])) ?? '',
      label: readString(pick(json, ['label', 'title', 'name'])),
      at: at,
      note: readString(json['note']),
      done: readBool(pick(json, ['done', 'is_done', 'reached', 'completed', 'is_completed'])) ?? at != null,
    );
  }

  final String status;
  final String? label;
  final DateTime? at;
  final String? note;
  final bool done;
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    this.statusLabel,
    this.canCancel = false,
    this.subtotal,
    this.discount,
    this.deliveryFee,
    this.total,
    this.paymentMethod,
    this.paymentMethodLabel,
    this.customerName,
    this.phone,
    this.address,
    this.notes,
    this.couponCode,
    this.items = const [],
    this.itemsCount,
    this.timeline = const [],
    this.createdAt,
  });

  factory Order.fromJson(Json json) {
    final rawStatus = json['status'];
    final statusMap = rawStatus is Map ? asJson(rawStatus) : const <String, dynamic>{};
    final items = asJsonList(json['items']).map(OrderItem.fromJson).toList();
    return Order(
      id: readInt(json['id']) ?? 0,
      number: readString(pick(json, ['number', 'order_number'])) ?? '${json['id'] ?? ''}',
      status: rawStatus is Map ? readString(statusMap['key']) ?? '' : readString(rawStatus) ?? '',
      statusLabel: readString(json['status_label']) ?? readString(statusMap['label']),
      canCancel: readBool(json['can_cancel']) ?? false,
      subtotal: readDouble(json['subtotal']),
      discount: readDouble(json['discount']),
      deliveryFee: readDouble(json['delivery_fee']),
      total: readDouble(json['total']),
      paymentMethod: readString(json['payment_method']),
      paymentMethodLabel: readString(json['payment_method_label']),
      customerName: readString(json['customer_name']),
      phone: readString(json['phone']),
      address: readString(json['address']),
      notes: readString(json['notes']),
      couponCode: readString(json['coupon_code']),
      items: items,
      itemsCount: readInt(json['items_count']) ?? (items.isEmpty ? null : items.length),
      timeline: asJsonList(json['timeline']).map(TimelineStep.fromJson).toList(),
      createdAt: readDate(json['created_at']),
    );
  }

  final int id;
  final String number;
  final String status;
  final String? statusLabel;
  final bool canCancel;
  final double? subtotal;
  final double? discount;
  final double? deliveryFee;
  final double? total;
  final String? paymentMethod;

  /// Server-localized label, e.g. "Cash on delivery".
  final String? paymentMethodLabel;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? notes;
  final String? couponCode;
  final List<OrderItem> items;
  final int? itemsCount;
  final List<TimelineStep> timeline;
  final DateTime? createdAt;
}
