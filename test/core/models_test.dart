import 'dart:ui';

import 'package:digital_shelf/core/network/api_response.dart';
import 'package:digital_shelf/core/utils/formatters.dart';
import 'package:digital_shelf/core/utils/json.dart';
import 'package:digital_shelf/features/cart/data/cart.dart';
import 'package:digital_shelf/features/home/data/home_repository.dart';
import 'package:digital_shelf/features/orders/data/order.dart';
import 'package:digital_shelf/features/products/data/product_query.dart';
import 'package:digital_shelf/features/products/data/products_repository.dart';
import 'package:digital_shelf/features/reviews/data/review.dart';
import 'package:digital_shelf/shared/models/category.dart';
import 'package:digital_shelf/shared/models/product.dart';
import 'package:digital_shelf/shared/models/store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  group('captured live payloads', () {
    test('store branding, delivery and currency', () {
      final store = Store.fromJson(asJson(fixtureData('store.json')));
      expect(store.name, 'Digital Shelf');
      expect(store.slug, 'digitalshelf');
      expect(store.primaryColor, const Color(0xFF6366F1));
      expect(store.currencySymbol, '₪');
      expect(store.deliveryFee, 10);
      expect(store.minOrder, 25);
      expect(store.logo, startsWith('https://'));
    });

    test('home sections', () {
      final home = HomeData.fromJson(asJson(fixtureData('home.json')));
      expect(home.categories, isNotEmpty);
      expect(home.newest, isNotEmpty);
      expect(home.banners, isEmpty);
      expect(home.isEmpty, isFalse);
    });

    test('categories with product counts', () {
      final categories = asJsonList(fixtureData('categories.json')).map(Category.fromJson).toList();
      expect(categories.first.name, 'Classics');
      expect(categories.first.productsCount, 1);
      expect(categories.first.icon, 'book-open');
    });

    test('product list with pagination meta and nullable images', () {
      final body = fixture('products.json');
      final products = asJsonList(body['data']).map(Product.fromJson).toList();
      final meta = PageMeta.fromJson(asJson(body['meta']));
      expect(meta.lastPage, 1);
      final maze = products.firstWhere((p) => p.name == 'The Maze Runner');
      expect(maze.image, isNull);
      expect(maze.gallery, isEmpty);
      expect(maze.subtitle, 'James Dashner');
      expect(products.first.attributes.map((a) => a.key), contains('pages'));
      expect(products.every((p) => p.options.isEmpty), isTrue, reason: 'API exposes no options');
    });

    test('product details are wrapped in data.product', () {
      final details = ProductDetails.fromJson(asJson(fixtureData('product_107.json')));
      expect(details.product.id, 107);
      expect(details.product.finalPrice, 30);
      expect(details.product.inStock, isTrue);
      expect(details.related, isA<List<Product>>());
      expect(details.reviews.count, 0);
      expect(details.reviews.distribution.keys, containsAll([1, 2, 3, 4, 5]));
    });
  });

  group('contract-based payloads (spec examples)', () {
    test('cart summary from OpenAPI example', () {
      final cart = Cart.fromJson({
        'items': [],
        'items_count': 0,
        'subtotal': 0.0,
        'discount': 0.0,
        'delivery_fee': 0.0,
        'total': 0.0,
        'coupon_code': null,
        'coupon_error': null,
        'min_order': 50.0,
        'meets_min_order': false,
        'currency': 'ILS',
      });
      expect(cart.isEmpty, isTrue);
      expect(cart.meetsMinOrder, isFalse);
      expect(cart.minOrder, 50);
    });

    test('cart item tolerates flattened and nested product shapes', () {
      final flat = CartItem.fromJson({'id': 3, 'product_id': 9, 'name': 'A', 'quantity': 2, 'unit_price': 12.5, 'line_total': 25});
      expect((flat.productId, flat.unitPrice, flat.lineTotal), (9, 12.5, 25.0));

      final nested = CartItem.fromJson({
        'id': 4,
        'quantity': '1',
        'options': {'size': 'M'},
        'product': {'id': 7, 'name': 'B', 'final_price': 30, 'thumb': 't.webp', 'stock': 5},
      });
      expect((nested.productId, nested.name, nested.unitPrice, nested.image, nested.stock), (7, 'B', 30.0, 't.webp', 5));
      expect(nested.options, {'size': 'M'});
    });

    test('order with timeline and can_cancel', () {
      final order = Order.fromJson({
        'id': 12,
        'number': 'DS-0012',
        'status': 'pending',
        'can_cancel': true,
        'total': 40,
        'payment_method': 'cash',
        'items': [
          {'product_name': 'Book', 'quantity': 1, 'price': 30, 'total': 30},
        ],
        'timeline': [
          {'status': 'pending', 'label': 'بانتظار التأكيد', 'at': '2026-10-21T08:00:00+00:00', 'done': true},
          {'status': 'confirmed', 'label': 'تم التأكيد', 'at': null, 'done': false},
          {'status': 'preparing', 'at': null},
        ],
      });
      expect(order.canCancel, isTrue);
      expect(order.items.single.name, 'Book');
      expect(order.timeline.map((t) => t.done), [true, false, false]);
      expect(order.timeline.first.at, isNotNull);
    });

    test('order status as object', () {
      final order = Order.fromJson({'id': 1, 'status': {'key': 'shipped', 'label': 'Shipped'}});
      expect((order.status, order.statusLabel, order.number), ('shipped', 'Shipped', '1'));
      expect(order.canCancel, isFalse, reason: 'absent can_cancel must never enable cancellation');
    });

    test('review from OpenAPI example', () {
      final review = Review.fromJson({
        'id': 5,
        'rating': 5,
        'comment': 'وصل بسرعة',
        'is_visible': true,
        'customer': {'name': 'أحمد سمارة', 'initials': 'أس'},
        'created_at': '2026-09-21T11:10:00+00:00',
      });
      expect((review.rating, review.customerName, review.initials), (5, 'أحمد سمارة', 'أس'));
    });
  });

  group('ProductQuery', () {
    test('maps every documented filter to query parameters', () {
      const query = ProductQuery(
        q: ' novel ',
        categoryId: 40,
        minPrice: 50,
        maxPrice: 300.5,
        inStock: true,
        featured: true,
        sort: ProductSort.bestSelling,
        descending: true,
      );
      expect(query.toQuery(page: 2), {
        'q': 'novel',
        'category_id': 40,
        'min_price': 50,
        'max_price': 300.5,
        'in_stock': 1,
        'featured': 1,
        'sort': 'best_selling',
        'order': 'desc',
        'page': 2,
        'per_page': 15,
      });
    });

    test('omits unset filters and has value equality', () {
      expect(const ProductQuery().toQuery(page: 1), {'page': 1, 'per_page': 15});
      expect(const ProductQuery(q: 'a', inStock: true), const ProductQuery(q: 'a', inStock: true));
      expect(const ProductQuery(q: 'a').hashCode, const ProductQuery(q: 'a').hashCode);
    });
  });

  test('money formatting keeps API amounts unchanged', () {
    expect(formatMoney(30, '₪'), '30 ₪');
    expect(formatMoney(25.5, '₪'), '25.50 ₪');
    expect(formatMoney(1250, ''), '1,250');
  });
}
