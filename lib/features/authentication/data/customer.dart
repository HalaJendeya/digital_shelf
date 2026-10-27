import '../../../core/utils/json.dart';

class Customer {
  const Customer({required this.id, required this.name, this.email, this.phone, this.avatar});

  /// Accepts either the customer object itself or a wrapper (`{customer: {...}}`
  /// / `{user: {...}}`) — the exact auth payload is not documented.
  factory Customer.fromJson(Json json) {
    final inner = pick(json, ['customer', 'user']);
    final source = inner is Map ? asJson(inner) : json;
    return Customer(
      id: readInt(source['id']) ?? 0,
      name: readString(source['name']) ?? '',
      email: readString(source['email']),
      phone: readString(source['phone']),
      avatar: readString(pick(source, ['avatar_url', 'avatar'])),
    );
  }

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => String.fromCharCode(p.runes.first)).join();
  }
}
