// Tolerant JSON readers. The backend is the source of truth, but several payloads
// are undocumented, so models read fields defensively instead of crashing.

typedef Json = Map<String, dynamic>;

Json asJson(Object? value) =>
    value is Map ? value.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

List<Json> asJsonList(Object? value) =>
    value is List ? value.whereType<Map>().map(asJson).toList() : const [];

int? readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

double? readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? readBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return null;
}

String? readString(Object? value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

DateTime? readDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// Returns the first non-null value among [keys].
Object? pick(Json json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}
