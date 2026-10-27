# Digital Shelf — Implementation Report

Date: 2026-10-21 · Flutter 3.44.9 / Dart 3.12.2 · Riverpod 3.4 · Dio 5.11 · GoRouter 18

See [API_INVENTORY.md](API_INVENTORY.md) for the full endpoint inventory.

## 1. Architecture

Feature-first; each feature splits **data** (models + repository, the only code
that touches `ApiClient`), **application** (Riverpod notifiers/providers), and
**presentation** (widgets). Widgets never make HTTP calls.

```
lib/
├── main.dart                     ProviderScope (Riverpod auto-retry disabled), prefs, intl
├── app/  app.dart · router/ (GoRouter + bottom-nav shell) · l10n/ (ar/en strings)
├── design_system/  design_system.dart (barrel)
│   ├── tokens/  app_colors (palette, light/dark ColorSchemes, opacity) · app_dimensions (Gap, Radii, IconSizes, AvatarSizes, AppSizes, AppDurations)
│   ├── theme/   app_theme (buildAppTheme) · status_colors · app_text_styles (ThemeExtensions) · theme_context (context.colors/status/textStyles)
│   └── components/  AppSpinner · AppTag
├── core/ config/ · network/ (ApiClient, interceptors, envelope) · error/ (AppException) · storage/ (secure token) · utils/
├── shared/ models/ (Product, Category, Store, PagedState, PagedController) · widgets/ (image, states, price, stepper…)
└── features/
    store · splash · authentication · home · categories · products · search
    cart · checkout · orders · favorites · reviews · profile
```

Key decisions

| Concern | Approach |
|---|---|
| Envelope | `ApiClient` unwraps `{success,data,meta}`; any failure (incl. `success:false` in a 200) → `AppException(type, code, statusCode, fieldErrors)` |
| Auth | Token in `flutter_secure_storage`, mirrored in memory for the Dio interceptor; 401 on a token request signs out globally |
| Retries | `RetryInterceptor`: GET only, 2 retries on connection errors/timeouts/502-504. POST/PUT/PATCH/DELETE (checkout!) never retried. Riverpod's provider auto-retry is disabled |
| Caching | Store, home, categories, cart, favorites, orders are keep-alive providers; tabs use `StatefulShellRoute.indexedStack`, so tab switches never refetch. Images via `cached_network_image` |
| Request cancellation | Listings are auto-disposed family providers keyed by `ProductQuery`; disposal cancels the `CancelToken`, so a new search query cancels the obsolete request |
| Search | 400 ms debounce; filters persist across query edits |
| Pricing | All totals displayed verbatim from the API (`subtotal`, `discount`, `delivery_fee`, `total`, `meets_min_order`); the client never computes them |
| Favorites sync | One `FavoritesController` list; `isFavoriteProvider(id)` drives every heart (cards, details, favorites page). Optimistic, reconciled with the server's `is_favorite`, reverted on error |
| Cart | Mutations serialized (rapid taps can't interleave); state replaced with the server's cart; re-fetch if a response has no cart |
| Checkout | Re-entrant submit ignored, button disabled, back navigation blocked while submitting; cart + orders invalidated after success |
| Locale | Arabic default, English switch in Account; persisted in SharedPreferences; sent as `Accept-Language`; server-localized providers refetch on change; Material RTL/LTR via `flutter_localizations` |
| Logging | Debug-only, method + path + status. Never headers, bodies, tokens or passwords |

## 2. Screen & navigation map

```
/splash ──(ping ∥ store ∥ restore session)──► /home
Bottom tabs (state preserved):
  /home ─ search bar → /search · banners → /product/:id | /products?category= · "see all" → /products?featured|sort
  /categories → /products?category=&title=
  /cart  (guest → login prompt) → /checkout 🔒 → /order-success/:id 🔒 → /orders/:id 🔒
  /account → /account/edit 🔒 (name, phone, email) · /orders 🔒 (status filter) · /favorites 🔒 · language · appearance · /about · logout
/products  (paged grid + filter/sort sheet)
/product/:id  (gallery, favorite, stock, attributes, description, reviews summary, related, add-to-cart)
  └─ /product/:id/reviews (paged) + write-review sheet 🔒
/search (debounced, filters, paged)
/about (store cover, description, delivery fee, minimum order, tap-to-call, WhatsApp)
/login?from=… ⇄ /register
```

🔒 = router redirect to `/login?from=<destination>`; after sign-in the user
continues to that destination. In-page actions (add to cart, favorite, review)
push `/login` over the current page and resume there after login.

## 3. Endpoint → feature coverage

Legend: **LT** implemented & live-tested · **MT** implemented & mock-tested ·
**UV** implemented but unverified (no automated test of that call) · **BB** blocked by backend · **NI** not implemented

| Endpoint | Feature | Status |
|---|---|---|
| GET `/ping` | Splash connectivity | **LT** |
| GET `/stores/{slug}` | Branding, theme color, currency, contact | **LT** (+ fixture test) |
| GET `/home` | Home sections | **LT** (+ fixture test) |
| GET `/categories` | Categories tab, filter sheet | **LT** (+ fixture test) |
| GET `/products` (q, category, price, stock, featured, sort/order, page) | Listing, search, filters, pagination | **LT** (sort by price asserted) + **MT** (debounced search) |
| GET `/products/{id}` | Details, related, reviews summary, `is_favorite` | **LT** as guest and signed in (`is_favorite`) |
| GET `/products/{id}/reviews` | Reviews list | **LT** (store has 0 reviews) + **MT** |
| POST `/auth/login` | Login | **LT** + **MT** (success, 422 field errors); 422 shape observed live |
| POST `/auth/register` | Register | **LT** + **MT** (contract) |
| GET `/auth/me` | Session restore, profile | **LT** + **MT** |
| PUT `/auth/profile` | Edit profile (name, phone, optional email) | **MT** (contract) |
| POST `/auth/logout` | Logout | **LT** + **MT** (local clear on failure) |
| GET `/cart` | Cart tab, badge | **LT** + **MT**; 401 shape observed live |
| POST `/cart/items` | Add to cart | **LT** + **MT** |
| PATCH `/cart/items/{id}` | Quantity | **LT** + **MT** (contract) |
| DELETE `/cart/items/{id}` | Remove item | **LT** + **MT** (re-fetch fallback) |
| DELETE `/cart` | Clear cart | **LT** + **MT** (contract) |
| POST `/cart/coupon` | Apply coupon | **LT** + **MT** (error keeps cart) |
| DELETE `/cart/coupon` | Remove coupon | **LT** + **MT** (contract) |
| POST `/checkout` | Checkout (`cash`, `card_demo`) | **LT** + **MT** (cash live; `card_demo` mock only) (duplicate guard, 422) |
| GET `/orders` | Order history (paged, `status` filter) | **LT** + **MT** (contract + widget) |
| GET `/orders/{id}` | Details + timeline | **LT** + **MT** |
| POST `/orders/{id}/cancel` | Cancel when `can_cancel` | **LT** + **MT** (contract + E2E journey) |
| POST `/favorites/{id}` | Toggle favorite | **LT** + **MT** |
| GET `/favorites` | Favorites page | **LT** + **MT** |
| POST `/products/{id}/reviews` | Submit review / `REVIEW_REQUIRES_PURCHASE` | **LT** + **MT** |

Nothing is **BB** or **NI** among customer endpoints. Owner/admin endpoints in the
platform spec are intentionally out of scope.

## 4. API validation findings

1. Envelope matches the documentation, plus an undocumented `status` integer on errors.
2. `GET /products/{id}` returns `data.product` (wrapped), unlike list endpoints — handled.
3. `Accept-Language: en` switches server messages (e.g. `"Please log in first"`); product
   attribute labels and store description remain Arabic (store content).
4. Products carry `attributes_display` with server-formatted values (e.g. "460 صفحة"); used as-is.
5. No `options` field exists on any product in this store, so no option picker appears.
6. `rating` appears only on the detail payload; `reviews_summary.distribution` keys are strings `"1"…"5"`.
7. Several products have `image: null` and empty `images`; a placeholder is shown.
8. The collection's search example (`q=فستان`, dress) belongs to a clothing store; this is a book store.
9. Spec documents `PUT /auth/profile` as multipart with optional `email`/`avatar`; the
   collection sends JSON `name`/`phone`. The app sends JSON `name`/`phone` per the collection.
10. Spec documents an optional `status` filter on `GET /orders` (unused by the UI).

## 5. Known limitations

- Protected endpoints were live-verified with one authorized QA customer (section 10).
  `PUT /auth/profile` and the `card_demo` payment method were not exercised live.
- Undocumented shapes — cart `items[]`, order objects/`timeline` entries, login/register
  payloads (token is read from `data.token`), favorites list items — are parsed
  defensively (several candidate keys, all nullable). Confirm them with one authorized
  run; adjust `CartItem.fromJson`, `Order.fromJson`, `TimelineStep.fromJson` if needed.
- Banners section is implemented but untested visually — the store has no banners today.
- `card_demo` is labelled as a demo with an explicit notice; no card data is collected.
- No running device was available in this session (Android emulator offline), so the app
  was not exercised end-to-end on screen. Widget tests cover key screens.
- The project's original template `test/widget_test.dart` (counter test) was no longer
  on disk when tests were added; it was not restored because it targeted the removed
  counter demo.

## 6. Setup

```bash
flutter pub get
flutter run                                  # defaults to souqna.toldpath.com / digitalshelf
flutter run --dart-define=API_BASE_URL=https://… --dart-define=STORE_SLUG=…
flutter analyze
flutter test                                 # unit, provider, widget tests (offline)
flutter test test/live --dart-define=LIVE_API=true   # read-only live contract checks
```

## 7. Verification (this session)

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 63 passed, 4 skipped (live tests, opt-in): API client, models, repository contracts for all 26 endpoints, controllers, screens, full E2E journey |
| `flutter test test/live --dart-define=LIVE_API=true` | 3/3 passed against the real API |
| Android debug build (`flutter build apk --debug`) | Built `build/app/outputs/flutter-apk/app-debug.apk` |

## 8. Next steps (need your input)

1. Provide test customer credentials (or authorize creating one) to live-verify cart,
   checkout, orders, favorites and reviews, then pin the undocumented payload shapes.
2. Run on a device/emulator for a visual pass (Arabic RTL, small phones, dark mode).

## 9. Completion pass (gap review)

Implemented after a full review of the app against the brief, the collection and the OpenAPI spec:

| Gap | Resolution |
|---|---|
| Expired sessions (401) silently became guest mode | `AuthState.sessionExpired` + app-wide snack bar via a shared `ScaffoldMessenger` key |
| Checkout could show stale totals | Cart is re-fetched when checkout opens |
| Order success was empty when opened without the in-memory order | Falls back to `GET /orders/{id}` |
| Cart content ignored language changes | Cart provider refetches on locale change |
| `status` filter on `GET /orders` unused | Status chips on order history |
| Profile email not editable (spec allows `email`) | Editable, validated, sent only when changed |
| Store description/cover/delivery terms never shown; contact not actionable | About screen with tap-to-call and WhatsApp (`url_launcher`, Android `<queries>`) |
| Only system light/dark | Appearance setting (system/light/dark), persisted |
| Login/register and home search rows overflowed on narrow phones / large text | `Wrap` and ellipsized text (caught by the E2E test) |
| No repository or end-to-end tests | Contract tests for every endpoint; E2E journey test through router, auth redirect and Dio |

Deliberately not implemented:

- **Avatar upload** (`PUT /auth/profile` multipart `avatar`): the spec documents it, but a
  multipart `PUT` usually isn't parsed by the Laravel-style backend this API appears to use,
  and it can't be verified without credentials. Adding it blind risks a broken feature.
- **Platform-level endpoints** (`/auth/change-password`, `/notifications`, `/search`, owner/admin)
  belong to store owners and the platform account, not store customers.

## 10. Live verification with the authorized QA customer (2026-10-21)

With your authorization, one test customer was registered on `digitalshelf`
(credentials in `test/live/live_customer.local.json`, git-ignored; template in
`live_customer.example.json`). Every response was captured, and the redacted payloads
are in `test/fixtures/live_*.json`, pinned by `test/core/live_payloads_test.dart`.

| Flow | Live result |
|---|---|
| Register / login | `201`/`200`, `data.token` + `data.user` (already parsed correctly) |
| Me / logout | Profile returned; after logout `/auth/me` → `401 UNAUTHENTICATED` |
| Favorites | Toggle returns `{product_id, is_favorite}`; list is flat products; details reflect `is_favorite` |
| Cart | Add, change quantity, remove, clear, coupon remove all return the full cart; items are flat with `original_price` and `is_available` |
| Cart errors | `COUPON_INVALID` (422), `OUT_OF_STOCK` (422, `details.available`), `PRODUCT_UNAVAILABLE` (404), quantity > 100 → 422 field error |
| Cash checkout | `201`, order `SQ-1001`, `payment_method_label`, 5-step timeline `{status,label,done,at,note}`; cart emptied |
| Orders | History paginated; `status=delivered` filter works; details include `can_cancel` |
| Cancel | `cancelled`, `can_cancel:false`, timeline → pending ✓ · cancelled ✓; second cancel → `ORDER_NOT_CANCELLABLE` (422) |
| Review | No rating → 422; not delivered → `403 REVIEW_REQUIRES_PURCHASE` |

App changes made from these findings:
- Cart lines show the struck-through `original_price` and a "No longer available" warning (`is_available`).
- Quantity steppers stop at `min(stock, 100)`, matching backend validation.
- Generic 422 messages ("The given data was invalid") are replaced by the first field error.
- Orders show the server's localized `payment_method_label`.

Re-run the whole flow at any time (it places one cash order and cancels it):

```bash
flutter test test/live/live_customer_flow_test.dart --dart-define=LIVE_MUTATIONS=true
```

Data left on the live store: QA customer account #124 and two cancelled test orders
(`SQ-1001` from the manual capture, and one from the repository-level run), both marked
"TEST ORDER - automated QA". Favorites and cart are empty, and all tokens are revoked.
