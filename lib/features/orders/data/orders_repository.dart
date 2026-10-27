import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import 'order.dart';

enum PaymentMethod {
  cash('cash'),

  /// Backend demo mode — no real charge, no card details collected.
  cardDemo('card_demo');

  const PaymentMethod(this.apiValue);
  final String apiValue;
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    this.notes,
  });

  final String customerName;
  final String phone;
  final String address;
  final String? notes;
  final PaymentMethod paymentMethod;

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'phone': phone,
    'address': address,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    'payment_method': paymentMethod.apiValue,
  };
}

class OrdersRepository {
  OrdersRepository(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  String get _store => _config.storePath;

  /// `POST /checkout` — not retried automatically (non-idempotent).
  Future<Order> checkout(CheckoutRequest request) async =>
      Order.fromJson((await _api.post('$_store/checkout', body: request.toJson())).json);

  /// Order statuses in pipeline order (plus `cancelled`), as used by the
  /// backend's tracking timeline and the optional `status` filter.
  static const statuses = ['pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled'];

  Future<Paginated<Order>> fetchOrders({int page = 1, String? status, CancelToken? cancelToken}) async {
    final response = await _api.get(
      '$_store/orders',
      query: {'page': page, 'status': ?status},
      cancelToken: cancelToken,
    );
    final items = response.list.map(Order.fromJson).toList();
    return Paginated(
      items: items,
      meta: response.pageMeta ?? PageMeta(page: page, perPage: items.length, total: items.length, lastPage: page),
    );
  }

  Future<Order> fetchOrder(int id) async => Order.fromJson((await _api.get('$_store/orders/$id')).json);

  /// Returns the updated order when the response includes it.
  Future<Order?> cancel(int id) async {
    final json = (await _api.post('$_store/orders/$id/cancel')).json;
    return json.containsKey('id') ? Order.fromJson(json) : null;
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider)),
);
