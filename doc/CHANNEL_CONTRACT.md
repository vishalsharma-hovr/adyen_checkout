# Channel contract

## Platform view

| Item | Value |
|------|--------|
| View type | `dev.adyen_checkout/card_view` |
| Event channel | `dev.adyen_checkout/card_view_$id` |

### Creation params

`clientKey`, `environment`, `sessionId`, `sessionData`, `merchantAccount`, `holderNameRequired`, `storePaymentFieldVisible`, …

### Events (native → Dart)

| Method | Payload |
|--------|---------|
| `onLoaded` | — |
| `onFinished` | `{ resultCode, sessionId?, sessionData?, sessionResult? }` |
| `onError` | `{ message }` |
| `onAction` | `{ type }` |

## Wallet method channel

| Item | Value |
|------|--------|
| Channel | `dev.adyen_checkout/wallet` |

### Methods

| Method | Platform | Result |
|--------|----------|--------|
| `startGooglePay` | Android | JSON string or map with `resultCode` (+ optional session fields) |
| `startApplePay` | iOS | map with `resultCode` |

### Common error codes

`MISSING_PARAM`, `MISSING_CLIENT_KEY`, `MISSING_CONFIG`, `USER_DISMISSED`, `CANCELLED`, `SESSION_ERROR`, `NO_GOOGLE_PAY`, `GOOGLE_PAY_UNAVAILABLE`, `NOT_SUPPORTED`, `SESSION_INIT_FAILED`
