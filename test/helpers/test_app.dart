import 'package:digital_shelf/core/providers.dart';
import 'package:digital_shelf/core/storage/token_storage.dart';
import 'package:digital_shelf/features/store/data/store_repository.dart';
import 'package:digital_shelf/shared/models/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testStore = Store(id: 25, name: 'Digital Shelf', slug: 'digitalshelf', currencySymbol: '₪');

Future<List<Override>> baseOverrides({String? token}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    tokenStorageProvider.overrideWithValue(MemoryTokenStorage(token)),
    storeProvider.overrideWith((_) async => testStore),
  ];
}

/// Pumps [child] inside a localized MaterialApp with the given overrides.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [...await baseOverrides(), ...overrides],
      child: MaterialApp(
        locale: locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
