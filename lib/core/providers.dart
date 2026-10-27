import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'network/interceptors.dart';
import 'storage/token_storage.dart';

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.fromEnvironment());

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>((_) => SecureTokenStorage());

/// In-memory copy of the session token, read synchronously by the Dio interceptor.
class SessionToken extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? token) => state = token;
}

final sessionTokenProvider = NotifierProvider<SessionToken, String?>(SessionToken.new);

/// Fires whenever an authenticated request comes back 401.
final unauthorizedSignalProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ---- Locale ---------------------------------------------------------------

class LocaleController extends Notifier<Locale> {
  static const _key = 'locale';
  static const supported = [Locale('ar'), Locale('en')];

  @override
  Locale build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return Locale(saved == 'en' ? 'en' : 'ar');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

// ---- Appearance -----------------------------------------------------------

/// Light / dark / follow-system, persisted per device.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Lets non-widget code (session expiry) show snack bars app-wide.
final scaffoldMessengerKeyProvider = Provider((_) => GlobalKey<ScaffoldMessengerState>());

// ---- Networking -----------------------------------------------------------

/// Transport override for tests (null = Dio's platform adapter).
final httpAdapterProvider = Provider<HttpClientAdapter?>((_) => null);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    contentType: Headers.jsonContentType,
  ));
  final adapter = ref.watch(httpAdapterProvider);
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll([
    HeadersInterceptor(
      languageCode: () => ref.read(localeProvider).languageCode,
      token: () => ref.read(sessionTokenProvider),
    ),
    UnauthorizedInterceptor(() => ref.read(unauthorizedSignalProvider).value++),
    RetryInterceptor(dio),
    if (kDebugMode) SafeLogInterceptor(),
  ]);
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
