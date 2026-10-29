import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _configJson = '''
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

void main() {
  testWidgets('drop-in sheet uses the app theme surface, including dark mode', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAdyenCardDropIn(
              context,
              config: AdyenConfig.fromJson(_configJson),
              sessionId: 'session',
              sessionData: 'data',
            ),
            child: const Text('Pay'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.backgroundColor, scheme.surface);
  });
}
