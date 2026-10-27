import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/providers.dart';
import '../../../shared/models/paged_controller.dart';
import '../../../shared/models/paged_state.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/order.dart';
import '../data/orders_repository.dart';

/// Selected status filter for the order history (`null` = all).
class OrderStatusFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? status) => state = status;
}

final orderStatusFilterProvider = NotifierProvider<OrderStatusFilter, String?>(OrderStatusFilter.new);

class OrdersController extends PagedController<Order> {
  String? _status;

  @override
  Future<PagedState<Order>> build() {
    ref.watch(localeProvider);
    _status = ref.watch(orderStatusFilterProvider);
    if (!ref.watch(isAuthenticatedProvider)) {
      return Future.value(const PagedState(items: [], page: 1, lastPage: 1));
    }
    return super.build();
  }

  @override
  Future<Paginated<Order>> fetchPage(int page, CancelToken cancelToken) =>
      ref.read(ordersRepositoryProvider).fetchOrders(page: page, status: _status, cancelToken: cancelToken);
}

final ordersControllerProvider = AsyncNotifierProvider<OrdersController, PagedState<Order>>(OrdersController.new);

class OrderDetailsController extends AsyncNotifier<Order> {
  OrderDetailsController(this.orderId);

  final int orderId;

  @override
  Future<Order> build() {
    ref.watch(localeProvider);
    return ref.read(ordersRepositoryProvider).fetchOrder(orderId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Cancels only when the backend reports `can_cancel`; then reloads the
  /// order so status and timeline come from the server.
  Future<void> cancel() async {
    final current = state.value;
    if (current == null || !current.canCancel) return;
    final repo = ref.read(ordersRepositoryProvider);
    final updated = await repo.cancel(orderId) ?? await repo.fetchOrder(orderId);
    if (!ref.mounted) return;
    state = AsyncData(updated);
    ref.invalidate(ordersControllerProvider);
  }
}

final orderDetailsProvider = AsyncNotifierProvider.autoDispose.family<OrderDetailsController, Order, int>(
  OrderDetailsController.new,
);
