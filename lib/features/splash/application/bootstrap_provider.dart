import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../authentication/application/auth_controller.dart';
import '../../store/data/store_repository.dart';

/// Startup sequence: connectivity check, store configuration and session
/// restore run concurrently. Completes once the app can show the storefront.
final bootstrapProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(storeRepositoryProvider);
  final results = await Future.wait<Object?>([
    repo.ping(),
    ref.read(storeProvider.future),
    ref.read(authControllerProvider.notifier).restore(),
  ]);
  if (results.first != true) {
    throw const AppException(type: AppErrorType.server, message: '');
  }
});
