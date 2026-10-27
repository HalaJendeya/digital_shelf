import '../utils/json.dart';

class PageMeta {
  const PageMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PageMeta.fromJson(Json json) => PageMeta(
    page: readInt(json['page']) ?? 1,
    perPage: readInt(json['per_page']) ?? 15,
    total: readInt(json['total']) ?? 0,
    lastPage: readInt(json['last_page']) ?? 1,
  );

  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

/// Unwrapped success envelope: `{ success, message, data, meta }`.
class ApiResponse {
  const ApiResponse({required this.data, this.message, this.meta});

  final Object? data;
  final String? message;
  final Json? meta;

  Json get json => asJson(data);
  List<Json> get list => asJsonList(data);
  PageMeta? get pageMeta => meta == null ? null : PageMeta.fromJson(meta!);
}

class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;
}
