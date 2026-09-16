# Apple Pay merchant identifier

## What it is

An Apple Pay **Merchant ID** (`merchant.…`) created in your Apple Developer account. It identifies your app to Apple Pay.

It is **not** the same as Adyen’s `merchantAccount` string in Customer Area.

## Where it goes in this plugin

In the host app config JSON:

```json
"applePay": {
  "merchantIdentifier": "merchant.com.example.app"
}
```

`AdyenCheckout.startApplePay` reads `applePay.merchantIdentifier` and passes it to the native Apple Pay component. The plugin never invents a default Merchant ID. An empty value raises `AdyenException` with code `missingConfig`.

## Apple Developer setup

1. Certificates, Identifiers & Profiles → **Identifiers** → **Merchant IDs** → create an ID (e.g. `merchant.com.example.app`).
2. Create a **Payment Processing Certificate** and complete certificate setup per Apple’s and Adyen’s Apple Pay documentation.
3. Enable the **Apple Pay** capability on your iOS App ID and select the Merchant ID.

## Xcode / host app

1. Open the Runner (host) target → **Signing & Capabilities** → **Apple Pay**.
2. Add the same Merchant ID.
3. Confirm the entitlements file contains:

```xml
<key>com.apple.developer.in-app-payments</key>
<array>
  <string>merchant.com.example.app</string>
</array>
```

## Adyen Customer Area

Configure Apple Pay with the **same** Merchant ID / certificates so Sessions can authorize Apple Pay.

## Config + runtime

- Different apps / flavors may use different Merchant IDs via different JSON files.
- Pass-through only — keep JSON, entitlements, and Adyen CA aligned.

## Test vs production

- Use sandbox Apple IDs and test devices with Adyen `environment: test`.
- Production Merchant ID + live Adyen environment for App Store builds.

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Mismatch / auth failures | JSON Merchant ID ≠ entitlements ≠ Adyen CA |
| Capability missing | Wrong team or Apple Pay not enabled on App ID |
| `NOT_SUPPORTED` | Device/simulator limitations or missing params |
| `CANCELLED` | User dismissed the sheet |
| `SESSION_INIT_FAILED` | Bad session / client key / environment |

Placeholder only: `merchant.com.example.app`. Do not commit production Merchant IDs into this plugin’s `example/` folder.
