import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Example uses placeholder config only — replace with real session data from your backend.
  await AdyenCheckout.initializeFromAsset();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adyen_checkout example')),
        body: const Center(
          child: Text(
            'Initialize with assets/adyen/adyen_config.json,\n'
            'then call AdyenCheckout.startCardDropIn / startGooglePay / startApplePay\n'
            'with sessionId + sessionData from your backend.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
