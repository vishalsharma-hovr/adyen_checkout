import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads placeholder config from asset', (WidgetTester tester) async {
    final config = await AdyenConfig.fromAsset();
    expect(config.merchantAccount, isNotEmpty);
    expect(config.applePay.merchantIdentifier, isNotEmpty);
  });
}
