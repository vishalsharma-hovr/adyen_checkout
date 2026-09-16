import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'config/adyen_config.dart';
import 'method_channel_adyen_checkout.dart';
import 'models/adyen_session_result.dart';

abstract class AdyenCheckoutPlatform extends PlatformInterface {
  AdyenCheckoutPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdyenCheckoutPlatform _instance = MethodChannelAdyenCheckout();

  static AdyenCheckoutPlatform get instance => _instance;

  static set instance(AdyenCheckoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<AdyenSessionResult> startGooglePay({
    required AdyenConfig config,
    required String sessionId,
    required String sessionData,
    int? amountMinorUnits,
  });

  Future<AdyenSessionResult> startApplePay({
    required AdyenConfig config,
    required String sessionId,
    required String sessionData,
  });
}
