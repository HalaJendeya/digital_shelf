import 'dart:ui';

import '../../core/utils/json.dart';

class Store {
  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.tagline,
    this.description,
    this.logo,
    this.cover,
    this.typeName,
    this.primaryColor,
    this.phone,
    this.whatsapp,
    this.address,
    this.deliveryFee,
    this.minOrder,
    this.currency = '',
    this.currencySymbol = '',
  });

  factory Store.fromJson(Json json) {
    final theme = asJson(json['theme']);
    final contact = asJson(json['contact']);
    final delivery = asJson(json['delivery']);
    return Store(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']) ?? '',
      slug: readString(json['slug']) ?? '',
      tagline: readString(json['tagline']),
      description: readString(json['description']),
      logo: readString(json['logo']),
      cover: readString(json['cover']),
      typeName: readString(asJson(json['type'])['name']),
      primaryColor: parseHexColor(readString(theme['primary_color'])),
      phone: readString(contact['phone']),
      whatsapp: readString(contact['whatsapp']),
      address: readString(contact['address']),
      deliveryFee: readDouble(delivery['fee']),
      minOrder: readDouble(delivery['min_order']),
      currency: readString(json['currency']) ?? '',
      currencySymbol: readString(json['currency_symbol']) ?? readString(json['currency']) ?? '',
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? tagline;
  final String? description;
  final String? logo;
  final String? cover;
  final String? typeName;
  final Color? primaryColor;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final double? deliveryFee;
  final double? minOrder;
  final String currency;
  final String currencySymbol;
}

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null || value.length != 8 ? null : Color(parsed);
}
