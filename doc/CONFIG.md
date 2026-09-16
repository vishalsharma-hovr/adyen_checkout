# Configuration

Each consuming app ships its own Adyen config asset(s).

## Asset paths

| Path | Purpose |
|------|---------|
| `assets/adyen/adyen_config.json` | Default |
| `assets/adyen/adyen_config.test.json` | Optional test flavor |

Select at runtime:

- `AdyenConfig.fromAsset('assets/adyen/adyen_config.test.json')`
- or `--dart-define=ADYEN_CONFIG_ASSET=assets/adyen/adyen_config.test.json`

Register the folder in the **host** `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/adyen/
```

## Schema

```json
{
  "clientKey": "test_YOUR_CLIENT_KEY",
  "environment": "test",
  "merchantAccount": "YOUR_MERCHANT_ACCOUNT",
  "merchantName": "Your Store",
  "countryCode": "US",
  "currencyCode": "USD",
  "shopperLocale": "en-US",
  "applePay": {
    "merchantIdentifier": "merchant.com.example.app"
  },
  "googlePay": {
    "merchantName": "Your Store",
    "allowedCardNetworks": ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"]
  },
  "card": {
    "holderNameRequired": false,
    "storePaymentFieldVisible": true
  }
}
```

### `environment`

`test` | `US` | `EU` | `AU` | `IN` | `APSE` (case-insensitive aliases accepted).

### Client key overlay

After loading JSON, a non-empty `--dart-define=ADYEN_CLIENT_KEY=...` (or native meta-data / Info.plist `ADYEN_CLIENT_KEY` as native fallback) overrides `clientKey`.

All other fields remain file-owned.

## Validation

Missing required keys throw `AdyenConfigException` before native calls.
Apple Pay requires `applePay.merchantIdentifier` — see [APPLE_PAY_MERCHANT_IDENTIFIER.md](APPLE_PAY_MERCHANT_IDENTIFIER.md).
