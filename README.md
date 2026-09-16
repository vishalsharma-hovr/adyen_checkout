# adyen_checkout

Config-driven Flutter plugin for Adyen Sessions **card**, **Google Pay**, and **Apple Pay**.

Consuming apps supply their own `assets/adyen/adyen_config.json`. This package does not embed merchant accounts, Apple merchant IDs, or production client keys.

## Quick start

```dart
await AdyenCheckout.initializeFromAsset(); // or AdyenConfig.fromAsset(...)

final result = await AdyenCheckout.startCardDropIn(
  context,
  sessionId: sessionId,
  sessionData: sessionData,
);

await AdyenCheckout.startGooglePay(
  sessionId: sessionId,
  sessionData: sessionData,
);

await AdyenCheckout.startApplePay(
  sessionId: sessionId,
  sessionData: sessionData,
);
```

## Docs

- [CONFIG.md](doc/CONFIG.md) — JSON schema and overlays
- [APPLE_PAY_MERCHANT_IDENTIFIER.md](doc/APPLE_PAY_MERCHANT_IDENTIFIER.md)
- [CHANNEL_CONTRACT.md](doc/CHANNEL_CONTRACT.md)
- [LOCAL_DEVELOPMENT.md](doc/LOCAL_DEVELOPMENT.md)

## Local development

Develop under `~/Documents/packages/adyen_checkout` and path-override from the host app. See [LOCAL_DEVELOPMENT.md](doc/LOCAL_DEVELOPMENT.md).
