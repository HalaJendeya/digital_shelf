/// Build-time configuration. Override with `--dart-define`, e.g.
/// `flutter run --dart-define=API_BASE_URL=https://staging.example.com/api/v1`.
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.storeSlug,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://souqna.toldpath.com/api/v1',
    ),
    storeSlug: String.fromEnvironment(
      'STORE_SLUG',
      defaultValue: 'digitalshelf',
    ),
  );

  final String baseUrl;
  final String storeSlug;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Prefix for every store-scoped path, e.g. `/stores/digitalshelf`.
  String get storePath => '/stores/$storeSlug';
}
