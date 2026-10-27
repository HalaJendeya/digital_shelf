# Digital Shelf

Flutter storefront for the **Digital Shelf** book store on the Souqna platform
(`https://souqna.toldpath.com/api/v1`, store slug `digitalshelf`).

Riverpod · Dio · GoRouter · flutter_secure_storage · cached_network_image · Arabic/English (RTL/LTR).

```bash
flutter pub get
flutter run
flutter test
flutter test test/live --dart-define=LIVE_API=true   # read-only checks against the real API
```

Override the backend with `--dart-define=API_BASE_URL=…` and `--dart-define=STORE_SLUG=…`.

- [docs/API_INVENTORY.md](docs/API_INVENTORY.md) — endpoints, contracts, verification status
- [docs/REPORT.md](docs/REPORT.md) — architecture, navigation map, coverage, findings, limitations

## Download

Android APK (v1.0.0, Android 7.0+): [releases/digital-shelf-v1.0.0.apk](releases/digital-shelf-v1.0.0.apk).
Enable "Install unknown apps" for your browser or file manager to sideload it.

## Release builds

Release signing reads `android/key.properties` (not committed):

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=C:/path/to/upload-keystore.jks
```

Without it, release builds fall back to the debug key. Regenerate the launcher icon with
`dart run tool/generate_icon.dart && dart run flutter_launcher_icons`.
