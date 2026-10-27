# Digital Shelf — API Inventory

Sources: `souqna-digitalshelf.postman_collection.json`, the platform's published OpenAPI
spec (`https://souqna.toldpath.com/docs/openapi.yaml`), and live read-only calls made on
2026-10-21.

- Base URL: `https://souqna.toldpath.com/api/v1`
- Store slug: `digitalshelf`
- Headers: `Accept: application/json`, `Accept-Language: ar|en` (verified: messages switch language)
- Auth: `Authorization: Bearer <token>` (token returned by login/register as `data.token`)

## Envelope (verified live)

```json
{ "success": true,  "message": "...", "data": {...} | [...], "meta": {page, per_page, total, last_page}? }
{ "success": false, "message": "...", "status": 422, "error": { "code": "VALIDATION_ERROR", "details": { "field": ["msg"] } } }
```

Observed error codes: `NOT_FOUND` (404), `STORE_NOT_FOUND` (404), `UNAUTHENTICATED` (401),
`VALIDATION_ERROR` (422, `details` = field → messages). Documented: `REVIEW_REQUIRES_PURCHASE` (403).

## Endpoints

| # | Method | Path (under `/stores/{slug}` unless noted) | Auth | Purpose | Verified |
|---|--------|------|------|---------|----------|
| 1 | GET | `/ping` (root) | – | Health: `data.pong`, `version`, `time` | Live |
| 2 | GET | `/stores/{slug}` | – | Store: name, logo, cover, `theme.primary_color`, contact, `delivery.fee/min_order`, `currency_symbol` | Live |
| 3 | GET | `/home` | – | `store`, `banners`, `categories`, `featured`, `newest`, `best_sellers` | Live |
| 4 | GET | `/categories` | – | List with `products_count`, `icon`, `image` | Live |
| 5 | GET | `/products` | – (opt.) | Filters: `q, category_id, min_price, max_price, in_stock, featured, sort(price|newest|best_selling|rating|name), order(asc|desc), page, per_page` → paginated | Live |
| 6 | GET | `/products/{id}` | optional | `data.product`, `data.related`, `data.reviews_summary{average,count,distribution,latest}`; `is_favorite` with token | Live (guest) |
| 7 | GET | `/products/{id}/reviews` | – | Paginated reviews `{id, rating, comment, customer{name, initials}, created_at}` | Live (empty) + spec example |
| 8 | POST | `/auth/register` | – | `name, email, phone, password, password_confirmation, device_name?` → token | Contract only |
| 9 | POST | `/auth/login` | – | `email, password, device_name?` → token | 422 shape live; success contract only |
| 10 | GET | `/auth/me` | ✔ | Current customer | Contract only |
| 11 | PUT | `/auth/profile` | ✔ | `name, phone` (spec also lists `email`, multipart `avatar`) | Contract only |
| 12 | POST | `/auth/logout` | ✔ | Revoke token | Contract only |
| 13 | GET | `/cart` | ✔ | `{items, items_count, subtotal, discount, delivery_fee, total, coupon_code, coupon_error, min_order, meets_min_order, currency}` | 401 live; shape from spec |
| 14 | POST | `/cart/items` | ✔ | `product_id, quantity?, options?` → cart | Contract only |
| 15 | PATCH | `/cart/items/{item}` | ✔ | `quantity` → cart | Contract only |
| 16 | DELETE | `/cart/items/{item}` | ✔ | → cart | Contract only |
| 17 | DELETE | `/cart` | ✔ | Clear → cart | Contract only |
| 18 | POST | `/cart/coupon` | ✔ | `code` → cart | Contract only |
| 19 | DELETE | `/cart/coupon` | ✔ | → cart | Contract only |
| 20 | POST | `/checkout` | ✔ | `customer_name, phone, address, notes?, payment_method(cash|card_demo)` → order (`id`, `number`) | Contract only |
| 21 | GET | `/orders` | ✔ | Paginated; optional `status` filter | Contract only |
| 22 | GET | `/orders/{id}` | ✔ | Order + `timeline`, `can_cancel` | Contract only |
| 23 | POST | `/orders/{id}/cancel` | ✔ | Only while `pending` / `can_cancel` | Contract only |
| 24 | POST | `/favorites/{productId}` | ✔ | Toggle → `is_favorite` | Contract only |
| 25 | GET | `/favorites` | ✔ | Product list (not paginated per spec) | Contract only |
| 26 | POST | `/products/{id}/reviews` | ✔ | `rating, comment` → 403 `REVIEW_REQUIRES_PURCHASE` unless delivered order | Contract only |

## Dependencies between endpoints

- Splash: `ping` ∥ `stores/{slug}` (concurrent) → restore token → `auth/me`.
- Cart item ids come from `cart.items[].id`; cart responses return the full summary.
- Checkout requires a non-empty cart that `meets_min_order`; returns order `id` used by `/orders/{id}`.
- Reviews require a delivered order containing the product.

## Observations / uncertainties

1. Products in this store expose **no `options` field**, so no option picker is shown. The
   client sends `options` only if a product ever provides them as `{name: [values]}`.
2. Shapes of cart `items[]`, order objects, `timeline` entries, and auth payloads are not
   documented; models parse them defensively (several candidate keys, all nullable).
3. Home `banners` is currently empty; banner `link_type` is `product | category | none`.
4. `GET /products/{id}` wraps the product in `data.product` (unlike list endpoints).
5. No test credentials were supplied, so no protected endpoint was exercised with a valid token.
