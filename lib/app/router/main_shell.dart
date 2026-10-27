import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/application/cart_controller.dart';
import '../l10n/app_strings.dart';

/// Bottom navigation. `indexedStack` keeps each tab alive, so switching tabs
/// never re-fetches data.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final cartCount = ref.watch(cartCountProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: s.categories,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: s.cart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: s.account,
          ),
        ],
      ),
    );
  }
}
