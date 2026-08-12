# Nexora API v1 Contract

Base path: `/api/v1`

## Response envelope

Success:
```json
{"success":true,"data":{}}
```

Collection:
```json
{"success":true,"data":[],"meta":{"current_page":1,"last_page":1,"per_page":20,"total":0}}
```

Client errors use a stable error object:
```json
{"success":false,"error":{"code":"VALIDATION_ERROR","message":"Validation failed.","fields":{"email":["The email field is required."]}}}
```

## Authentication

- `POST /auth/register` — public
- `POST /auth/login` — public
- `GET /auth/me` — Bearer token
- `POST /auth/logout` — Bearer token

Successful auth returns:
```json
{"success":true,"data":{"user":{},"token":"...","token_type":"Bearer"}}
```

## Wallets

- `GET /wallets`
- `POST /wallets`
- `GET /wallets/{wallet}`
- `PUT /wallets/{wallet}`
- `DELETE /wallets/{wallet}`

All wallet resources are scoped to the authenticated user.

## Transactions

- `GET /transactions`
- `POST /transactions`
- `GET /transactions/{transaction}`
- `PUT /transactions/{transaction}`
- `DELETE /transactions/{transaction}`

Supported transaction types: `income`, `expense`, `transfer`.

Income/expense require `wallet_id`. Transfers require different `source_wallet_id` and `destination_wallet_id` belonging to the authenticated user.

`POST /transactions` supports the `Idempotency-Key` header. Clients must generate a unique key per logical write and reuse it only when retrying that exact logical request.

## HTTP status policy

- `200` successful read/update/delete
- `201` successful creation
- `401` missing/invalid authentication
- `404` resource not found or not owned by current user
- `409` idempotency conflict
- `422` validation/business-rule failure
- `429` throttled
- `500` unexpected server failure

## Amounts and dates

- Money is serialized as decimal-compatible JSON values/strings and must never be treated as binary floating-point financial truth by the client.
- Timestamps are ISO-8601.
- The backend remains the financial source of truth; Flutter state is a cache/view of API data.
