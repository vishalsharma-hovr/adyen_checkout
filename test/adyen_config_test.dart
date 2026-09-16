import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdyenConfig', () {
    test('fromJson parses valid config', () {
      const json = '''
{
  "clientKey": "test_abc",
  "environment": "test",
  "merchantAccount": "YOUR_MERCHANT_ACCOUNT",
  "merchantName": "Your Store",
  "countryCode": "US",
  "currencyCode": "USD",
  "shopperLocale": "en-US",
  "applePay": { "merchantIdentifier": "merchant.com.example.app" },
  "googlePay": { "merchantName": "Your Store" },
  "card": { "holderNameRequired": true, "storePaymentFieldVisible": false }
}
''';
      final config = AdyenConfig.fromJson(json);
      expect(config.clientKey, 'test_abc');
      expect(config.environment, AdyenEnvironment.test);
      expect(config.environment.wireValue, 'test');
      expect(config.applePay.merchantIdentifier, 'merchant.com.example.app');
      expect(config.card.holderNameRequired, isTrue);
      expect(config.card.storePaymentFieldVisible, isFalse);
    });

    test('fromJson throws when merchantAccount missing', () {
      const json = '''
{
  "clientKey": "test_abc",
  "environment": "test",
  "merchantName": "Your Store",
  "countryCode": "US",
  "currencyCode": "USD",
  "applePay": { "merchantIdentifier": "merchant.com.example.app" },
  "googlePay": { "merchantName": "Your Store" }
}
''';
      expect(() => AdyenConfig.fromJson(json), throwsA(isA<AdyenConfigException>()));
    });

    test('environment aliases', () {
      expect(AdyenEnvironmentCodec.parse('US'), AdyenEnvironment.unitedStates);
      expect(AdyenEnvironmentCodec.parse('eu'), AdyenEnvironment.europe);
      expect(AdyenEnvironment.unitedStates.wireValue, 'US');
    });
  });

  group('AdyenSessionResult', () {
    test('fromMap', () {
      final result = AdyenSessionResult.fromMap({
        'resultCode': 'Authorised',
        'sessionId': 's1',
      });
      expect(result.isAuthorised, isTrue);
      expect(result.sessionId, 's1');
    });

    test('fromDynamic JSON string', () {
      final result = AdyenSessionResult.fromDynamic(
        '{"resultCode":"Authorised","sessionId":"s2"}',
      );
      expect(result.resultCode, 'Authorised');
      expect(result.sessionId, 's2');
    });
  });
}
