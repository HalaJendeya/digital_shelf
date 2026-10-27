import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../core/network/api_response.dart';
import 'paged_state.dart';

/// Base for paginated lists: first page via [build], further pages via
/// [loadMore]. In-flight requests are cancelled when the provider is disposed
/// (e.g. a search query changed), so stale responses never land.
abstract class PagedController<T> extends AsyncNotifier<PagedState<T>> {
  CancelToken? _cancelToken;

  Future<Paginated<T>> fetchPage(int page, CancelToken cancelToken);

  @override
  Future<PagedState<T>> build() async {
    final token = _cancelToken = CancelToken();
    ref.onDispose(() => token.cancel());
    return PagedState.fromPage(await fetchPage(1, token));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: () => null));
    try {
      final next = await fetchPage(current.page + 1, _cancelToken ?? CancelToken());
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on AppException catch (e) {
      if (!ref.mounted || e.type == AppErrorType.cancelled) return;
      state = AsyncData(current.copyWith(isLoadingMore: false, loadMoreError: () => e));
    }
  }
}
