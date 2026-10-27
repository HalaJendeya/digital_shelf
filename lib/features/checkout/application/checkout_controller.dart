import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_controller.dart';
import '../../orders/application/orders_providers.dart';
import '../../orders/data/order.dart';
import '../../orders/data/orders_repository.dart';

class CheckoutState {
  const CheckoutState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final Object? error;
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Places the order once. Re-entrant calls while a submission is in flight
  /// are ignored, preventing duplicate orders from double taps.
  Future<Order?> submit(CheckoutRequest request) async {
    if (state.isSubmitting) return null;
    state = const CheckoutState(isSubmitting: true);
    try {
      final order = await ref.read(ordersRepositoryProvider).checkout(request);
      ref.invalidate(cartControllerProvider);
      ref.invalidate(ordersControllerProvider);
      state = const CheckoutState();
      return order;
    } catch (e) {
      state = CheckoutState(error: e);
      rethrow;
    }
  }
}

final checkoutControllerProvider =
    NotifierProvider.autoDispose<CheckoutController, CheckoutState>(CheckoutController.new);
