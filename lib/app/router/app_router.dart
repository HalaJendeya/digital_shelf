import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/order_success_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/data/order.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/data/product_query.dart';
import '../../features/products/presentation/product_details_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/reviews/presentation/reviews_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/splash/application/bootstrap_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/store/presentation/about_store_screen.dart';
import 'main_shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const home = '/home';
  static const categories = '/categories';
  static const cart = '/cart';
  static const account = '/account';
  static const editProfile = '/account/edit';
  static const search = '/search';
  static const products = '/products';
  static const login = '/login';
  static const register = '/register';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const favorites = '/favorites';
  static const about = '/about';

  static String product(int id) => '/product/$id';
  static String reviews(int id) => '/product/$id/reviews';
  static String order(int id) => '/orders/$id';
  static String orderSuccess(int id) => '/order-success/$id';

  static String productList({int? categoryId, String? title, bool featured = false, ProductSort? sort}) => Uri(
    path: products,
    queryParameters: {
      if (categoryId != null) 'category': '$categoryId',
      'title': ?title,
      if (featured) 'featured': '1',
      if (sort != null) 'sort': sort.name,
    },
  ).toString();

  /// Routes that require a signed-in customer.
  static const protectedPrefixes = [checkout, orders, favorites, editProfile, '/order-success'];
}

/// Bridges Riverpod state changes to GoRouter's refresh mechanism.
class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(bootstrapProvider, (_, _) => refresh.notify());
  ref.listen(isAuthenticatedProvider, (_, _) => refresh.notify());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final ready = ref.read(bootstrapProvider).hasValue;
      if (!ready) return location == Routes.splash ? null : Routes.splash;
      if (location == Routes.splash) return Routes.home;

      final isProtected = Routes.protectedPrefixes.any(location.startsWith);
      if (isProtected && !ref.read(isAuthenticatedProvider)) {
        return Uri(path: Routes.login, queryParameters: {'from': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.categories, builder: (_, _) => const CategoriesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountScreen(),
                routes: [GoRoute(path: 'edit', builder: (_, _) => const EditProfileScreen())],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: Routes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: Routes.products,
        builder: (_, state) {
          final params = state.uri.queryParameters;
          return ProductListScreen(
            title: params['title'],
            initialQuery: ProductQuery(
              categoryId: int.tryParse(params['category'] ?? ''),
              featured: params['featured'] == '1',
              sort: ProductSort.values.asNameMap()[params['sort']],
              descending: params['sort'] != null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailsScreen(productId: _id(state)),
        routes: [
          GoRoute(
            path: 'reviews',
            builder: (_, state) => ReviewsScreen(productId: _id(state)),
          ),
        ],
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.checkout, builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: Routes.orders,
        builder: (_, _) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => OrderDetailsScreen(orderId: _id(state)),
          ),
        ],
      ),
      GoRoute(
        path: '/order-success/:id',
        builder: (_, state) =>
            OrderSuccessScreen(orderId: _id(state), order: state.extra is Order ? state.extra as Order : null),
      ),
      GoRoute(path: Routes.favorites, builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: Routes.about, builder: (_, _) => const AboutStoreScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

int _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
