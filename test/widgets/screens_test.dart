import 'package:digital_shelf/core/error/app_exception.dart';
import 'package:digital_shelf/core/network/api_response.dart';
import 'package:digital_shelf/features/authentication/application/auth_controller.dart';
import 'package:digital_shelf/features/authentication/data/auth_repository.dart';
import 'package:digital_shelf/features/authentication/presentation/login_screen.dart';
import 'package:digital_shelf/features/cart/data/cart.dart';
import 'package:digital_shelf/features/cart/data/cart_repository.dart';
import 'package:digital_shelf/features/cart/presentation/cart_screen.dart';
import 'package:digital_shelf/features/orders/data/order.dart';
import 'package:digital_shelf/features/orders/data/orders_repository.dart';
import 'package:digital_shelf/features/orders/presentation/order_details_screen.dart';
import 'package:digital_shelf/features/orders/presentation/orders_screen.dart';
import 'package:digital_shelf/features/products/data/product_query.dart';
import 'package:digital_shelf/features/products/data/products_repository.dart';
import 'package:digital_shelf/features/products/presentation/widgets/product_card.dart';
import 'package:digital_shelf/features/reviews/data/review.dart';
import 'package:digital_shelf/features/reviews/data/reviews_repository.dart';
import 'package:digital_shelf/features/reviews/presentation/write_review_sheet.dart';
import 'package:digital_shelf/features/search/presentation/search_screen.dart';
import 'package:digital_shelf/shared/models/product.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class MockOrdersRepository extends Mock implements OrdersRepository {}

class MockReviewsRepository extends Mock implements ReviewsRepository {}

class MockProductsRepository extends Mock implements ProductsRepository {}

const book = Product(
  id: 104,
  name: 'The Maze Runner',
  price: 25,
  finalPrice: 25,
  attributes: [ProductAttribute(key: 'author', label: 'Author', display: 'James Dashner')],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const ProductQuery());
    registerFallbackValue(CancelToken());
  });

  testWidgets('ProductCard shows API name, author and price with store currency', (tester) async {
    await pumpApp(tester, const Scaffold(body: SizedBox(width: 180, height: 300, child: ProductCard(product: book))));
    expect(find.text('The Maze Runner'), findsOneWidget);
    expect(find.text('James Dashner'), findsOneWidget);
    expect(find.text('25 ₪'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget, reason: 'fallback for a missing image');
  });

  testWidgets('Arabic locale lays out right-to-left with Arabic strings', (tester) async {
    const outOfStock = Product(id: 1, name: 'كتاب', price: 10, finalPrice: 10, inStock: false);
    await pumpApp(
      tester,
      const Scaffold(body: SizedBox(width: 180, height: 300, child: ProductCard(product: outOfStock))),
      locale: const Locale('ar'),
    );
    expect(Directionality.of(tester.element(find.byType(ProductCard))), TextDirection.rtl);
    expect(find.text('غير متوفر'), findsOneWidget);
  });

  group('LoginScreen', () {
    testWidgets('validates locally before calling the API', (tester) async {
      final repo = MockAuthRepository();
      await pumpApp(tester, const LoginScreen(), overrides: [authRepositoryProvider.overrideWithValue(repo)]);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('This field is required'), findsNWidgets(2));
      verifyNever(() => repo.login(email: any(named: 'email'), password: any(named: 'password')));
    });

    testWidgets('shows server field errors from 422', (tester) async {
      final repo = MockAuthRepository();
      when(() => repo.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
        const AppException(
          type: AppErrorType.validation,
          message: 'Invalid',
          fieldErrors: {'email': ['These credentials do not match our records.']},
        ),
      );
      await pumpApp(tester, const LoginScreen(), overrides: [authRepositoryProvider.overrideWithValue(repo)]);
      await tester.enterText(find.byType(TextFormField).first, 'user@example.test');
      await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('These credentials do not match our records.'), findsOneWidget);
    });
  });

  testWidgets('Cart blocks checkout below the minimum order and shows API totals', (tester) async {
    final repo = MockCartRepository();
    when(repo.fetchCart).thenAnswer((_) async => const Cart(
      items: [CartItem(id: 1, productId: 104, name: 'The Maze Runner', quantity: 1, unitPrice: 20, lineTotal: 20)],
      itemsCount: 1,
      subtotal: 20,
      discount: 0,
      deliveryFee: 10,
      total: 30,
      minOrder: 25,
      meetsMinOrder: false,
    ));
    await pumpApp(tester, const CartScreen(), overrides: [
      isAuthenticatedProvider.overrideWithValue(true),
      cartRepositoryProvider.overrideWithValue(repo),
    ]);
    expect(find.text('Minimum order is 25 ₪'), findsOneWidget);
    final checkout = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checkout · 30 ₪'));
    expect(checkout.onPressed, isNull);
    expect(find.text('10 ₪'), findsOneWidget, reason: 'delivery fee from API');
  });

  group('OrderDetailsScreen', () {
    Future<void> pumpOrder(WidgetTester tester, {required bool canCancel}) async {
      final repo = MockOrdersRepository();
      when(() => repo.fetchOrder(12)).thenAnswer((_) async => Order(
        id: 12,
        number: 'DS-12',
        status: 'pending',
        canCancel: canCancel,
        total: 35,
        timeline: [
          TimelineStep(status: 'pending', label: 'Pending', at: DateTime(2026, 10, 21), done: true),
          const TimelineStep(status: 'confirmed', label: 'Confirmed', done: false),
        ],
      ));
      await pumpApp(tester, const OrderDetailsScreen(orderId: 12), overrides: [
        ordersRepositoryProvider.overrideWithValue(repo),
      ]);
    }

    testWidgets('renders backend timeline and offers cancel when can_cancel', (tester) async {
      await pumpOrder(tester, canCancel: true);
      expect(find.text('#DS-12'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);
    });

    testWidgets('hides cancel when the backend says it is unavailable', (tester) async {
      await pumpOrder(tester, canCancel: false);
      expect(find.text('Cancel order'), findsNothing);
    });
  });

  testWidgets('Review submission explains REVIEW_REQUIRES_PURCHASE', (tester) async {
    final repo = MockReviewsRepository();
    when(() => repo.fetchReviews(104, page: any(named: 'page'), cancelToken: any(named: 'cancelToken'))).thenAnswer(
      (_) async => const Paginated<Review>(items: [], meta: PageMeta(page: 1, perPage: 15, total: 0, lastPage: 1)),
    );
    when(() => repo.submitReview(104, rating: any(named: 'rating'), comment: any(named: 'comment'))).thenThrow(
      const AppException(
        type: AppErrorType.forbidden,
        message: 'Forbidden',
        code: kReviewRequiresPurchase,
        statusCode: 403,
      ),
    );
    await pumpApp(tester, const Scaffold(body: WriteReviewSheet(productId: 104)), overrides: [
      reviewsRepositoryProvider.overrideWithValue(repo),
    ]);
    await tester.tap(find.byTooltip('5'));
    await tester.tap(find.widgetWithText(FilledButton, 'Submit review'));
    await tester.pumpAndSettle();
    expect(
      find.text('You can review this product once an order containing it has been delivered.'),
      findsOneWidget,
    );
  });

  testWidgets('Search debounces typing into a single API request', (tester) async {
    final repo = MockProductsRepository();
    when(() => repo.fetchProducts(any(), page: any(named: 'page'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => const Paginated(items: [book], meta: PageMeta(page: 1, perPage: 15, total: 1, lastPage: 1)));
    await pumpApp(tester, const SearchScreen(), overrides: [productsRepositoryProvider.overrideWithValue(repo)]);

    await tester.enterText(find.byType(TextField), 'ma');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'maze');
    await tester.pump(SearchScreen.debounce);
    await tester.pumpAndSettle();

    final captured = verify(
      () => repo.fetchProducts(captureAny(), page: 1, cancelToken: any(named: 'cancelToken')),
    ).captured;
    expect(captured.cast<ProductQuery>().map((q) => q.q), ['maze']);
    expect(find.text('The Maze Runner'), findsOneWidget);
  });

  testWidgets('Order history status chips filter through the API', (tester) async {
    final repo = MockOrdersRepository();
    when(() => repo.fetchOrders(page: any(named: 'page'), status: any(named: 'status'), cancelToken: any(named: 'cancelToken')))
        .thenAnswer((inv) async {
      final status = inv.namedArguments[#status] as String?;
      return Paginated(
        items: [Order(id: 1, number: status == null ? 'ALL-1' : 'DEL-1', status: status ?? 'pending')],
        meta: const PageMeta(page: 1, perPage: 15, total: 1, lastPage: 1),
      );
    });
    await pumpApp(tester, const OrdersScreen(), overrides: [
      isAuthenticatedProvider.overrideWithValue(true),
      ordersRepositoryProvider.overrideWithValue(repo),
    ]);
    expect(find.text('#ALL-1'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Delivered'));
    await tester.pumpAndSettle();
    expect(find.text('#DEL-1'), findsOneWidget);
    verify(() => repo.fetchOrders(page: 1, status: 'delivered', cancelToken: any(named: 'cancelToken'))).called(1);
  });
}
