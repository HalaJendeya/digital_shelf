// Contract tests: each repository call must hit the documented method, path,
// query and body, and parse the documented response.
import 'dart:convert';

import 'package:digital_shelf/core/config/app_config.dart';
import 'package:digital_shelf/core/network/api_client.dart';
import 'package:digital_shelf/features/authentication/data/auth_repository.dart';
import 'package:digital_shelf/features/cart/data/cart_repository.dart';
import 'package:digital_shelf/features/favorites/data/favorites_repository.dart';
import 'package:digital_shelf/features/home/data/home_repository.dart';
import 'package:digital_shelf/features/orders/data/orders_repository.dart';
import 'package:digital_shelf/features/products/data/product_query.dart';
import 'package:digital_shelf/features/products/data/products_repository.dart';
import 'package:digital_shelf/features/reviews/data/reviews_repository.dart';
import 'package:digital_shelf/features/store/data/store_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/fixtures.dart';

const config = AppConfig(baseUrl: 'https://api.test/v1', storeSlug: 'shop');

final cartJson = {
  'items': [
    {'id': 3, 'product_id': 9, 'name': 'Book', 'quantity': 2, 'unit_price': 15, 'line_total': 30},
  ],
  'items_count': 2,
  'subtotal': 30,
  'discount': 0,
  'delivery_fee': 10,
  'total': 40,
  'coupon_code': null,
  'coupon_error': null,
  'min_order': 25,
  'meets_min_order': true,
  'currency': 'ILS',
};

final pageMeta = {'page': 1, 'per_page': 15, 'total': 1, 'last_page': 1};

late FakeAdapter adapter;
late ApiClient api;

RequestOptions get last => adapter.requests.last;

void main() {
  Object? body() => last.data is String ? jsonDecode(last.data as String) : last.data;
  void respond(Object? data, {Map<String, dynamic>? meta}) =>
      adapter.handler = (_) => FakeResponse(200, ok(data, meta: meta));

  setUp(() {
    adapter = FakeAdapter((_) => FakeResponse(200, ok(null)));
    api = ApiClient(Dio(BaseOptions(baseUrl: config.baseUrl))..httpClientAdapter = adapter);
  });

  group('storefront (public)', () {
    test('ping and store', () async {
      final repo = StoreRepository(api, config);
      respond({'pong': true});
      expect(await repo.ping(), isTrue);
      expect((last.method, last.path), ('GET', '/ping'));

      respond(fixtureData('store.json'));
      expect((await repo.fetchStore()).name, 'Digital Shelf');
      expect(last.path, '/stores/shop');
    });

    test('home and categories', () async {
      final repo = HomeRepository(api, config);
      respond(fixtureData('home.json'));
      expect((await repo.fetchHome()).newest, isNotEmpty);
      expect(last.path, '/stores/shop/home');

      respond(fixtureData('categories.json'));
      expect(await repo.fetchCategories(), hasLength(4));
      expect(last.path, '/stores/shop/categories');
    });

    test('products listing sends filters; details parse wrapper', () async {
      final repo = ProductsRepository(api, config);
      respond(fixtureData('products.json'), meta: pageMeta);
      final page = await repo.fetchProducts(
        const ProductQuery(q: 'maze', categoryId: 56, inStock: true, sort: ProductSort.rating, descending: true),
        page: 2,
      );
      expect(page.items, isNotEmpty);
      expect(last.path, '/stores/shop/products');
      expect(last.queryParameters, {
        'q': 'maze',
        'category_id': 56,
        'in_stock': 1,
        'sort': 'rating',
        'order': 'desc',
        'page': 2,
        'per_page': 15,
      });

      respond(fixtureData('product_107.json'));
      expect((await repo.fetchDetails(107)).product.id, 107);
      expect(last.path, '/stores/shop/products/107');
    });

    test('reviews list and submit', () async {
      final repo = ReviewsRepository(api, config);
      respond([], meta: pageMeta);
      await repo.fetchReviews(107, page: 1);
      expect((last.method, last.path), ('GET', '/stores/shop/products/107/reviews'));
      expect(last.queryParameters, {'page': 1});

      respond({'id': 1});
      await repo.submitReview(107, rating: 4, comment: '  Great  ');
      expect((last.method, last.path), ('POST', '/stores/shop/products/107/reviews'));
      expect(body(), {'rating': 4, 'comment': 'Great'});
    });
  });

  group('customer account', () {
    test('login, register, me, profile, logout', () async {
      final repo = AuthRepository(api, config);
      respond({
        'token': 'tok',
        'customer': {'id': 1, 'name': 'A', 'email': 'a@test.dev'},
      });
      final login = await repo.login(email: 'a@test.dev', password: 'pw');
      expect((login.token, login.customer?.name), ('tok', 'A'));
      expect((last.method, last.path), ('POST', '/stores/shop/auth/login'));
      expect(body(), {'email': 'a@test.dev', 'password': 'pw', 'device_name': AuthRepository.deviceName});

      respond({'token': 'tok2'});
      final reg = await repo.register(
        name: 'A',
        email: 'a@test.dev',
        phone: '0599000000',
        password: 'Secret123',
        passwordConfirmation: 'Secret123',
      );
      expect(reg.customer, isNull);
      expect(last.path, '/stores/shop/auth/register');
      expect((body() as Map).keys, containsAll(['name', 'email', 'phone', 'password', 'password_confirmation']));

      respond({'id': 1, 'name': 'A'});
      expect((await repo.me()).name, 'A');
      expect((last.method, last.path), ('GET', '/stores/shop/auth/me'));

      await repo.updateProfile(name: 'B', phone: '0599111222');
      expect((last.method, last.path), ('PUT', '/stores/shop/auth/profile'));
      expect(body(), {'name': 'B', 'phone': '0599111222'}, reason: 'email omitted when unchanged');
      await repo.updateProfile(name: 'B', phone: '0599111222', email: 'b@test.dev');
      expect(body(), containsPair('email', 'b@test.dev'));

      await repo.logout();
      expect((last.method, last.path), ('POST', '/stores/shop/auth/logout'));
    });
  });

  group('cart', () {
    test('every mutation uses the documented route and returns the cart', () async {
      final repo = CartRepository(api, config);
      respond(cartJson);

      expect((await repo.fetchCart()).total, 40);
      expect((last.method, last.path), ('GET', '/stores/shop/cart'));

      await repo.addItem(productId: 9, quantity: 2);
      expect((last.method, last.path), ('POST', '/stores/shop/cart/items'));
      expect(body(), {'product_id': 9, 'quantity': 2});

      await repo.addItem(productId: 9, options: {'size': 'M'});
      expect(body(), containsPair('options', {'size': 'M'}));

      await repo.updateQuantity(3, 5);
      expect((last.method, last.path), ('PATCH', '/stores/shop/cart/items/3'));
      expect(body(), {'quantity': 5});

      await repo.removeItem(3);
      expect((last.method, last.path), ('DELETE', '/stores/shop/cart/items/3'));

      await repo.applyCoupon('WELCOME10');
      expect((last.method, last.path), ('POST', '/stores/shop/cart/coupon'));
      expect(body(), {'code': 'WELCOME10'});

      await repo.removeCoupon();
      expect((last.method, last.path), ('DELETE', '/stores/shop/cart/coupon'));

      final cleared = await repo.clear();
      expect((last.method, last.path), ('DELETE', '/stores/shop/cart'));
      expect(cleared?.itemsCount, 2);
    });

    test('a mutation without a cart payload returns null so callers re-fetch', () async {
      respond(null);
      expect(await CartRepository(api, config).removeItem(1), isNull);
    });
  });

  group('checkout and orders', () {
    test('checkout body, history filter, details, cancel', () async {
      final repo = OrdersRepository(api, config);
      respond({'id': 9, 'number': 'DS-9', 'status': 'pending', 'can_cancel': true});
      final order = await repo.checkout(const CheckoutRequest(
        customerName: 'A',
        phone: '0599000000',
        address: 'Street 1',
        notes: '  ',
        paymentMethod: PaymentMethod.cardDemo,
      ));
      expect(order.number, 'DS-9');
      expect((last.method, last.path), ('POST', '/stores/shop/checkout'));
      expect(body(), {'customer_name': 'A', 'phone': '0599000000', 'address': 'Street 1', 'payment_method': 'card_demo'});

      respond([], meta: pageMeta);
      await repo.fetchOrders(status: 'delivered');
      expect(last.path, '/stores/shop/orders');
      expect(last.queryParameters, {'page': 1, 'status': 'delivered'});
      await repo.fetchOrders();
      expect(last.queryParameters, {'page': 1});

      respond({'id': 9, 'number': 'DS-9', 'status': 'pending', 'timeline': []});
      expect((await repo.fetchOrder(9)).id, 9);
      expect(last.path, '/stores/shop/orders/9');

      respond({'id': 9, 'status': 'cancelled', 'can_cancel': false});
      expect((await repo.cancel(9))?.status, 'cancelled');
      expect((last.method, last.path), ('POST', '/stores/shop/orders/9/cancel'));
    });
  });

  group('favorites', () {
    test('list accepts products or wrappers; toggle reads is_favorite', () async {
      final repo = FavoritesRepository(api, config);
      respond([
        {'id': 1, 'name': 'Direct', 'price': 10},
        {'product': {'id': 2, 'name': 'Wrapped', 'price': 12}},
      ]);
      final list = await repo.fetchFavorites();
      expect(list.map((p) => p.name), ['Direct', 'Wrapped']);
      expect(list.every((p) => p.isFavorite), isTrue);
      expect(last.path, '/stores/shop/favorites');

      respond({'is_favorite': true});
      expect(await repo.toggle(5), isTrue);
      expect((last.method, last.path), ('POST', '/stores/shop/favorites/5'));
    });
  });
}
