// End-to-end customer journey through the real app (router, auth redirect,
// Dio stack, providers, screens) against an in-memory fake backend:
// browse → add to cart as guest → sign in → cart → checkout → track → cancel.
import 'dart:convert';

import 'package:digital_shelf/app/app.dart';
import 'package:digital_shelf/core/config/app_config.dart';
import 'package:digital_shelf/core/providers.dart';
import 'package:digital_shelf/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_adapter.dart';

/// Minimal stateful stand-in for the Souqna store API.
class FakeStoreBackend {
  static const token = 'test-token';
  static const product = {
    'id': 1,
    'name': 'Test Book',
    'price': 30,
    'final_price': 30,
    'stock': 10,
    'in_stock': true,
    'image': null,
    'images': [],
    'attributes_display': [],
  };

  int cartQty = 0;
  String orderStatus = 'pending';
  bool ordered = false;
  final calls = <String>[];

  Map<String, dynamic> get cart => {
    'items': [
      if (cartQty > 0)
        {'id': 11, 'product_id': 1, 'name': 'Test Book', 'quantity': cartQty, 'unit_price': 30, 'line_total': 30 * cartQty},
    ],
    'items_count': cartQty,
    'subtotal': 30 * cartQty,
    'discount': 0,
    'delivery_fee': 10,
    'total': cartQty == 0 ? 0 : 30 * cartQty + 10,
    'min_order': 25,
    'meets_min_order': 30 * cartQty >= 25,
  };

  Map<String, dynamic> get order => {
    'id': 9,
    'number': 'DS-9',
    'status': orderStatus,
    'can_cancel': orderStatus == 'pending',
    'total': 40,
    'payment_method': 'cash',
    'items': [
      {'name': 'Test Book', 'quantity': 1, 'total': 30},
    ],
    'timeline': [
      {'status': 'pending', 'label': 'Pending', 'at': '2026-10-21T08:00:00+00:00', 'done': true},
      {'status': 'confirmed', 'label': 'Confirmed', 'done': false},
    ],
  };

  FakeResponse handle(RequestOptions o) {
    final path = o.path.replaceFirst('/stores/shop', '');
    final route = '${o.method} $path';
    calls.add(route);
    final authed = o.headers['Authorization'] == 'Bearer $token';
    const protected = ['/cart', '/checkout', '/orders', '/favorites', '/auth/me', '/auth/logout'];
    if (protected.any(path.startsWith) && !authed) {
      return FakeResponse(401, errorBody(401, 'UNAUTHENTICATED', 'Please log in first'));
    }
    final body = o.data is String ? jsonDecode(o.data as String) as Map : (o.data as Map?) ?? {};

    return switch (route) {
      'GET /ping' => FakeResponse(200, ok({'pong': true})),
      'GET ' => FakeResponse(200, ok({'id': 1, 'name': 'Digital Shelf', 'slug': 'shop', 'currency_symbol': '₪'})),
      'GET /home' => FakeResponse(200, ok({'banners': [], 'categories': [], 'featured': [], 'newest': [product], 'best_sellers': []})),
      'GET /categories' => FakeResponse(200, ok([])),
      'GET /products/1' => FakeResponse(200, ok({
        'product': product,
        'related': [],
        'reviews_summary': {'average': 0, 'count': 0, 'distribution': {}, 'latest': []},
      })),
      'POST /auth/login' => body['password'] == 'Secret123'
          ? FakeResponse(200, ok({'token': token, 'customer': {'id': 1, 'name': 'Test User', 'phone': '0599000000'}}))
          : FakeResponse(422, errorBody(422, 'VALIDATION_ERROR', 'Invalid', {'email': ['Wrong credentials']})),
      'GET /favorites' => FakeResponse(200, ok([])),
      'GET /cart' => FakeResponse(200, ok(cart)),
      'POST /cart/items' => () {
        cartQty += (body['quantity'] as int?) ?? 1;
        return FakeResponse(200, ok(cart));
      }(),
      'POST /checkout' => () {
        ordered = true;
        cartQty = 0;
        return FakeResponse(200, ok(order));
      }(),
      'GET /orders' => FakeResponse(200, ok([if (ordered) order], meta: {'page': 1, 'per_page': 15, 'total': 1, 'last_page': 1})),
      'GET /orders/9' => FakeResponse(200, ok(order)),
      'POST /orders/9/cancel' => () {
        orderStatus = 'cancelled';
        return FakeResponse(200, ok(order));
      }(),
      _ => FakeResponse(404, errorBody(404, 'NOT_FOUND', 'Not found: $route')),
    };
  }
}

void main() {
  testWidgets('guest browses, signs in, checks out, tracks and cancels an order', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeStoreBackend();
    final storage = MemoryTokenStorage();

    await tester.pumpWidget(ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(baseUrl: 'https://api.test/v1', storeSlug: 'shop')),
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(storage),
        httpAdapterProvider.overrideWithValue(FakeAdapter(backend.handle)),
      ],
      child: const DigitalShelfApp(),
    ));
    await tester.pumpAndSettle();

    // Splash → home with API data.
    expect(find.text('Test Book'), findsOneWidget);
    expect(backend.calls, containsAll(['GET /ping', 'GET ', 'GET /home']));

    // Product details; adding to cart as a guest opens sign-in.
    await tester.tap(find.text('Test Book'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add to cart'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    // Wrong password shows the server's field error.
    await tester.enterText(find.byType(TextFormField).first, 'user@example.test');
    await tester.enterText(find.byType(TextFormField).last, 'nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong credentials'), findsOneWidget);

    // Correct password → back on the product, and the add-to-cart resumes.
    await tester.enterText(find.byType(TextFormField).last, 'Secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(await storage.read(), FakeStoreBackend.token, reason: 'token stored securely');
    expect(backend.calls, contains('POST /cart/items'));
    expect(find.text('Added to cart'), findsOneWidget);

    // Cart shows server totals (30 + 10 delivery).
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('Checkout · 40 ₪'), findsOneWidget);
    await tester.tap(find.text('Checkout · 40 ₪'));
    await tester.pumpAndSettle();

    // Checkout: name/phone prefilled from the profile; address required.
    final placeOrder = find.widgetWithText(FilledButton, 'Place order');
    await tester.scrollUntilVisible(placeOrder, 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(placeOrder);
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsOneWidget);
    expect(backend.calls, isNot(contains('POST /checkout')));

    await tester.enterText(find.widgetWithText(TextFormField, 'Address'), 'Gaza, Street 1');
    await tester.scrollUntilVisible(placeOrder, 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(placeOrder);
    await tester.pumpAndSettle();
    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.text('Order number: DS-9'), findsOneWidget);
    expect(backend.calls.where((c) => c == 'POST /checkout'), hasLength(1));

    // Track → details with timeline → cancel while pending.
    await tester.tap(find.text('Track order'));
    await tester.pumpAndSettle();
    expect(find.text('#DS-9'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('POST /orders/9/cancel'));
    expect(find.text('Cancel order'), findsNothing, reason: 'can_cancel is now false');

    // Let snack bar timers finish.
    await tester.pump(const Duration(seconds: 5));
  });
}
