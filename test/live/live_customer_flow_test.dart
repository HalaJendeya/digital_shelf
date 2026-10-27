// Full customer flow against the REAL store using the app's own repositories
// and the authorized QA customer. It places one cash order and cancels it, so
// it is opt-in:
//
//   flutter test test/live/live_customer_flow_test.dart --dart-define=LIVE_MUTATIONS=true
//
// Credentials are read from test/live/live_customer.local.json (git-ignored;
// see live_customer.example.json).
import 'dart:convert';
import 'dart:io';

import 'package:digital_shelf/core/config/app_config.dart';
import 'package:digital_shelf/core/error/app_exception.dart';
import 'package:digital_shelf/core/network/api_client.dart';
import 'package:digital_shelf/core/network/interceptors.dart';
import 'package:digital_shelf/features/authentication/data/auth_repository.dart';
import 'package:digital_shelf/features/cart/data/cart_repository.dart';
import 'package:digital_shelf/features/favorites/data/favorites_repository.dart';
import 'package:digital_shelf/features/orders/data/orders_repository.dart';
import 'package:digital_shelf/features/products/data/product_query.dart';
import 'package:digital_shelf/features/products/data/products_repository.dart';
import 'package:digital_shelf/features/reviews/data/reviews_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('LIVE_MUTATIONS');
final _credsFile = File('test/live/live_customer.local.json');

void main() {
  final skip = !_enabled
      ? 'set --dart-define=LIVE_MUTATIONS=true'
      : !_credsFile.existsSync()
      ? 'missing ${_credsFile.path}'
      : false;

  test('login → favorites → cart → cash checkout → cancel → review gate → logout', skip: skip, () async {
    final creds = jsonDecode(_credsFile.readAsStringSync()) as Map<String, dynamic>;
    final config = AppConfig.fromEnvironment();
    String? token;
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
      ..interceptors.add(HeadersInterceptor(languageCode: () => 'en', token: () => token));
    final api = ApiClient(dio);

    final auth = AuthRepository(api, config);
    final products = ProductsRepository(api, config);
    final favorites = FavoritesRepository(api, config);
    final cart = CartRepository(api, config);
    final orders = OrdersRepository(api, config);
    final reviews = ReviewsRepository(api, config);

    // Sign in.
    final session = await auth.login(email: creds['email'] as String, password: creds['password'] as String);
    token = session.token;
    expect(session.customer?.email, creds['email']);
    expect((await auth.me()).email, creds['email']);

    try {
      // Pick an in-stock product whose price meets the minimum order.
      final page = await products.fetchProducts(const ProductQuery(inStock: true, sort: ProductSort.price, descending: true));
      final product = page.items.first;

      // Favorites: on → visible in list and details → off.
      expect(await favorites.toggle(product.id), isTrue);
      expect((await favorites.fetchFavorites()).map((p) => p.id), contains(product.id));
      expect((await products.fetchDetails(product.id)).product.isFavorite, isTrue);
      expect(await favorites.toggle(product.id), isFalse);

      // Cart: start clean, add, change quantity, bad coupon, back to 1.
      await cart.clear();
      var current = (await cart.addItem(productId: product.id))!;
      final line = current.items.single;
      expect(line.productId, product.id);
      current = (await cart.updateQuantity(line.id, 2))!;
      expect(current.items.single.quantity, 2);
      expect(current.total, current.subtotal - current.discount + current.deliveryFee);
      await expectLater(
        cart.applyCoupon('NOT-A-REAL-CODE'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'COUPON_INVALID')),
      );
      current = (await cart.updateQuantity(line.id, 1))!;
      expect(current.meetsMinOrder, isTrue);

      // Cash checkout, clearly marked as a test.
      final order = await orders.checkout(CheckoutRequest(
        customerName: creds['name'] as String,
        phone: creds['phone'] as String,
        address: 'TEST ORDER - automated QA, please ignore',
        notes: 'Automated app QA test order - cancelled immediately',
        paymentMethod: PaymentMethod.cash,
      ));
      expect((order.status, order.canCancel, order.timeline.first.done), ('pending', true, true));
      expect((await cart.fetchCart()).isEmpty, isTrue, reason: 'checkout empties the cart');

      // Tracking and history.
      expect((await orders.fetchOrder(order.id)).number, order.number);
      expect((await orders.fetchOrders()).items.map((o) => o.id), contains(order.id));

      // Cancel, then a second cancel is refused.
      final cancelled = await orders.cancel(order.id) ?? await orders.fetchOrder(order.id);
      expect((cancelled.status, cancelled.canCancel), ('cancelled', false));
      await expectLater(
        orders.cancel(order.id),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'ORDER_NOT_CANCELLABLE')),
      );

      // Reviews require a delivered order.
      await expectLater(
        reviews.submitReview(product.id, rating: 5, comment: 'QA test review'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', kReviewRequiresPurchase)),
      );
    } finally {
      await auth.logout();
    }

    // The token is revoked server-side.
    await expectLater(auth.me(), throwsA(isA<AppException>().having((e) => e.isUnauthorized, '401', isTrue)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
