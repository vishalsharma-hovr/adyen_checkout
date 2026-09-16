import 'package:adyen_checkout_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows example home copy', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('adyen_checkout example'), findsOneWidget);
  });
}
