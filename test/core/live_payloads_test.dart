// Models parsed against real responses captured from the live store with the
// authorized QA customer (2026-10-21). Tokens are redacted in the fixtures.
import 'package:digital_shelf/app/l10n/app_strings.dart';
import 'package:digital_shelf/core/network/api_client.dart';
import 'package:digital_shelf/core/utils/json.dart';
import 'package:digital_shelf/features/authentication/data/customer.dart';
import 'package:digital_shelf/features/cart/data/cart.dart';
import 'package:digital_shelf/features/orders/data/order.dart';
import 'package:digital_shelf/features/reviews/data/reviews_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  test('register/login payload: data.token + data.user', () {
    final data = asJson(fixtureData('live_auth_register.json'));
    expect(data['token'], isNotNull);
    final customer = Customer.fromJson(data);
    expect((customer.id, customer.name, customer.phone), (124, 'QA Test Customer', '0599000111'));
  });

  test('cart with two lines', () {
    final cart = Cart.fromJson(asJson(fixtureData('live_cart.json')));
    expect(cart.items, hasLength(2));
    final first = cart.items.first;
    expect((first.productId, first.unitPrice, first.lineTotal, first.stock), (104, 25.0, 25.0, 50));
    expect(first.isAvailable, isTrue);
    expect(first.image, endsWith('_thumb.webp'));
    expect((cart.subtotal, cart.deliveryFee, cart.total, cart.meetsMinOrder), (50.0, 10.0, 60.0, true));
    expect(first.maxQuantity, 50, reason: 'capped by stock, below the 100 backend limit');
  });

  test('placed order with full timeline', () {
    final order = Order.fromJson(asJson(fixtureData('live_order.json')));
    expect((order.number, order.status, order.canCancel), ('SQ-1001', 'pending', true));
    expect((order.subtotal, order.deliveryFee, order.total), (25.0, 10.0, 35.0));
    expect(order.paymentMethodLabel, 'Cash on delivery');
    expect(order.items.single.unitPrice, 25);
    expect(order.items.single.lineTotal, 25);
    expect(order.timeline.map((t) => t.status), ['pending', 'confirmed', 'preparing', 'shipped', 'delivered']);
    expect(order.timeline.map((t) => t.done), [true, false, false, false, false]);
  });

  test('cancelled order: can_cancel false, timeline ends in cancelled', () {
    final order = Order.fromJson(asJson(fixtureData('live_order_cancelled.json')));
    expect((order.status, order.canCancel), ('cancelled', false));
    expect(order.timeline.last.status, 'cancelled');
  });

  test('order history list is paginated', () {
    final body = fixture('live_orders.json');
    final orders = asJsonList(body['data']).map(Order.fromJson).toList();
    expect(orders.single.number, 'SQ-1001');
    expect(body['meta'], containsPair('last_page', 1));
  });

  group('live error envelopes', () {
    const s = AppStrings('en');

    test('REVIEW_REQUIRES_PURCHASE is 403 with the documented code', () {
      final e = errorFromBody(fixture('live_error_review_requires_purchase.json'), 403);
      expect((e.statusCode, e.code), (403, kReviewRequiresPurchase));
    });

    test('OUT_OF_STOCK and COUPON_INVALID surface the server message', () {
      final stock = errorFromBody(fixture('live_error_out_of_stock.json'), 422);
      expect(stock.code, 'OUT_OF_STOCK');
      expect(s.errorMessage(stock), contains('In stock: 50'));
      expect(errorFromBody(fixture('live_error_coupon_invalid.json'), 422).code, 'COUPON_INVALID');
      expect(errorFromBody(fixture('live_error_order_not_cancellable.json'), 422).code, 'ORDER_NOT_CANCELLABLE');
    });

    test('generic 422 message is replaced by the first field error', () {
      final e = errorFromBody({
        'success': false,
        'message': 'The given data was invalid',
        'error': {
          'code': 'VALIDATION_ERROR',
          'details': {
            'quantity': ['The quantity field must not be greater than 100.'],
          },
        },
      }, 422);
      expect(s.errorMessage(e), 'The quantity field must not be greater than 100.');
    });
  });
}
