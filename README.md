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
