import 'dart:async';

import 'package:digital_shelf/core/error/app_exception.dart';
import 'package:digital_shelf/core/providers.dart';
import 'package:digital_shelf/core/storage/token_storage.dart';
import 'package:digital_shelf/features/authentication/application/auth_controller.dart';
import 'package:digital_shelf/features/authentication/data/auth_repository.dart';
import 'package:digital_shelf/features/authentication/data/customer.dart';
import 'package:digital_shelf/features/cart/application/cart_controller.dart';
import 'package:digital_shelf/features/cart/data/cart.dart';
import 'package:digital_shelf/features/cart/data/cart_repository.dart';
import 'package:digital_shelf/features/checkout/application/checkout_controller.dart';
import 'package:digital_shelf/features/favorites/application/favorites_controller.dart';
import 'package:digital_shelf/features/favorites/data/favorites_repository.dart';
import 'package:digital_shelf/features/orders/data/order.dart';
import 'package:digital_shelf/features/orders/data/orders_repository.dart';
import 'package:digital_shelf/shared/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockOrdersRepository extends Mock implements OrdersRepository {}

Cart cartWith(int count, {double total = 0}) => Cart(
  items: [for (var i = 0; i < count; i++) CartItem(id: i + 1, productId: 100 + i, name: 'P$i', quantity: 1)],
  itemsCount: count,
  subtotal: total,
  discount: 0,
  deliveryFee: 10,
  total: total,
  meetsMinOrder: true,
);

const customer = Customer(id: 1, name: 'Test User', email: 't@example.test');
const request = CheckoutRequest(
  customerName: 'Test',
  phone: '0599000000',
  address: 'Street',
  paymentMethod: PaymentMethod.cash,
);

void main() {
  setUpAll(() => registerFallbackValue(request));

  late MockAuthRepository auth;
  late MockCartRepository cartRepo;
  late MockFavoritesRepository favRepo;
  late MockOrdersRepository ordersRepo;
  late MemoryTokenStorage storage;

  Future<ProviderContainer> makeContainer({String? token}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = MemoryTokenStorage(token);
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(auth),
        cartRepositoryProvider.overrideWithValue(cartRepo),
        favoritesRepositoryProvider.overrideWithValue(favRepo),
        ordersRepositoryProvider.overrideWithValue(ordersRepo),
      ],
    );
    return container;
  }

  setUp(() {
    auth = MockAuthRepository();
    cartRepo = MockCartRepository();
    favRepo = MockFavoritesRepository();
    ordersRepo = MockOrdersRepository();
  });

  group('AuthController', () {
    test('restores a saved token and loads the profile', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      final c = await makeContainer(token: 'saved');
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(authControllerProvider).customer?.name, 'Test User');
      expect(c.read(sessionTokenProvider), 'saved');
    });

    test('a 401 during restore clears the session', () async {
      when(() => auth.me()).thenThrow(const AppException(type: AppErrorType.unauthorized, message: ''));
      final c = await makeContainer(token: 'revoked');
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(authControllerProvider).status, AuthStatus.guest);
      expect(await storage.read(), isNull);
      expect(c.read(sessionTokenProvider), isNull);
    });

    test('a network error during restore keeps the user signed in', () async {
      when(() => auth.me()).thenThrow(const AppException(type: AppErrorType.network, message: ''));
      final c = await makeContainer(token: 'saved');
      await c.read(authControllerProvider.notifier).restore();
      expect(c.read(isAuthenticatedProvider), isTrue);
    });

    test('login stores the token securely and fetches the profile when absent', () async {
      when(() => auth.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const AuthResult(token: 'new-token'));
      when(() => auth.me()).thenAnswer((_) async => customer);
      final c = await makeContainer();
      await c.read(authControllerProvider.notifier).login(email: 'a@b.c', password: 'x');
      expect(await storage.read(), 'new-token');
      expect(c.read(authControllerProvider).customer, customer);
    });

    test('logout clears locally even if the server call fails', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      when(() => auth.logout()).thenThrow(const AppException(type: AppErrorType.network, message: ''));
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      await c.read(authControllerProvider.notifier).logout();
      expect(c.read(isAuthenticatedProvider), isFalse);
      expect(c.read(authControllerProvider).sessionExpired, isFalse, reason: "a deliberate logout is not an expiry");
      expect(await storage.read(), isNull);
    });

    test('unauthorized signal from the network layer signs the user out', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      c.read(unauthorizedSignalProvider).value++;
      await Future<void>.delayed(Duration.zero);
      expect(c.read(isAuthenticatedProvider), isFalse);
      expect(c.read(authControllerProvider).sessionExpired, isTrue, reason: "UI shows a session-expired notice");
    });
  });

  group('CartController', () {
    test('guests get an empty cart without any request', () async {
      final c = await makeContainer();
      await c.read(authControllerProvider.notifier).restore();
      expect(await c.read(cartControllerProvider.future), same(Cart.empty));
      verifyNever(() => cartRepo.fetchCart());
    });

    test('mutations replace state with the API cart; badge follows items_count', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      when(() => cartRepo.fetchCart()).thenAnswer((_) async => cartWith(0));
      when(() => cartRepo.addItem(productId: 5, quantity: 2, options: const {}))
          .thenAnswer((_) async => cartWith(2, total: 60));
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      await c.read(cartControllerProvider.future);

      await c.read(cartControllerProvider.notifier).addItem(5, quantity: 2);
      expect(c.read(cartControllerProvider).value!.total, 60);
      expect(c.read(cartCountProvider), 2);
    });

    test('re-fetches when a mutation response carries no cart', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      var fetches = 0;
      when(() => cartRepo.fetchCart()).thenAnswer((_) async => cartWith(fetches++ == 0 ? 2 : 1));
      when(() => cartRepo.removeItem(1)).thenAnswer((_) async => null);
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      await c.read(cartControllerProvider.future);

      await c.read(cartControllerProvider.notifier).removeItem(1);
      expect(c.read(cartControllerProvider).value!.itemsCount, 1);
    });

    test('a failed mutation keeps the last good cart and surfaces the error', () async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      when(() => cartRepo.fetchCart()).thenAnswer((_) async => cartWith(1));
      when(() => cartRepo.applyCoupon('BAD')).thenThrow(
        const AppException(type: AppErrorType.validation, message: 'Invalid coupon'),
      );
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      await c.read(cartControllerProvider.future);

      await expectLater(c.read(cartControllerProvider.notifier).applyCoupon('BAD'), throwsA(isA<AppException>()));
      expect(c.read(cartControllerProvider).value!.itemsCount, 1);
    });
  });

  group('FavoritesController', () {
    const product = Product(id: 7, name: 'Book', price: 20, finalPrice: 20);

    Future<ProviderContainer> signedIn() async {
      when(() => auth.me()).thenAnswer((_) async => customer);
      when(() => favRepo.fetchFavorites()).thenAnswer((_) async => []);
      final c = await makeContainer(token: 't');
      await c.read(authControllerProvider.notifier).restore();
      await c.read(favoritesControllerProvider.future);
      return c;
    }

    test('optimistic toggle is visible everywhere via isFavoriteProvider', () async {
      final completer = Completer<bool>();
      when(() => favRepo.toggle(7)).thenAnswer((_) => completer.future);
      final c = await signedIn();
      final key = (id: 7, fallback: false);

      final pending = c.read(favoritesControllerProvider.notifier).toggle(product);
      expect(c.read(isFavoriteProvider(key)), isTrue, reason: 'optimistic');
      completer.complete(true);
      await pending;
      expect(c.read(isFavoriteProvider(key)), isTrue);
    });

    test('reconciles with the server result and reverts on failure', () async {
      when(() => favRepo.toggle(7)).thenAnswer((_) async => false);
      final c = await signedIn();
      await c.read(favoritesControllerProvider.notifier).toggle(product);
      expect(c.read(favoritesControllerProvider).value, isEmpty);

      when(() => favRepo.toggle(7)).thenThrow(const AppException(type: AppErrorType.network, message: ''));
      await expectLater(c.read(favoritesControllerProvider.notifier).toggle(product), throwsA(isA<AppException>()));
      expect(c.read(favoritesControllerProvider).value, isEmpty);
    });
  });

  group('CheckoutController', () {
    test('ignores duplicate submissions while one is in flight', () async {
      final completer = Completer<Order>();
      when(() => ordersRepo.checkout(any())).thenAnswer((_) => completer.future);
      final c = await makeContainer();
      final sub = c.listen(checkoutControllerProvider, (_, _) {});

      final first = c.read(checkoutControllerProvider.notifier).submit(request);
      final second = await c.read(checkoutControllerProvider.notifier).submit(request);
      expect(second, isNull);
      completer.complete(const Order(id: 9, number: 'DS-9', status: 'pending'));
      expect((await first)!.number, 'DS-9');
      verify(() => ordersRepo.checkout(any())).called(1);
      sub.close();
    });

    test('surfaces validation errors and allows a retry', () async {
      when(() => ordersRepo.checkout(any())).thenThrow(
        const AppException(type: AppErrorType.validation, message: 'x', fieldErrors: {'address': ['required']}),
      );
      final c = await makeContainer();
      final sub = c.listen(checkoutControllerProvider, (_, _) {});
      await expectLater(c.read(checkoutControllerProvider.notifier).submit(request), throwsA(isA<AppException>()));
      expect(c.read(checkoutControllerProvider).isSubmitting, isFalse);
      sub.close();
    });
  });
}
