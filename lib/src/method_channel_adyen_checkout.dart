import 'package:flutter/services.dart';

import 'adyen_checkout_channels.dart';
import 'adyen_checkout_platform.dart';
import 'config/adyen_config.dart';
import 'models/adyen_exception.dart';
import 'models/adyen_session_result.dart';

class MethodChannelAdyenCheckout extends AdyenCheckoutPlatform {
  MethodChannelAdyenCheckout({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(AdyenCheckoutChannels.wallet);

  final MethodChannel _channel;

  @override
  Future<AdyenSessionResult> startGooglePay({
    required AdyenConfig config,
    required String sessionId,
    required String sessionData,
    int? amountMinorUnits,
  }) {
    return _invoke(
      'startGooglePay',
      config.toWalletArgs(
        sessionId: sessionId,
        sessionData: sessionData,
        amountMinorUnits: amountMinorUnits,
      ),
    );
  }

  @override
  Future<AdyenSessionResult> startApplePay({
    required AdyenConfig config,
    required String sessionId,
    required String sessionData,
  }) {
    return _invoke(
      'startApplePay',
      config.toWalletArgs(sessionId: sessionId, sessionData: sessionData),
    );
  }

  Future<AdyenSessionResult> _invoke(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(method, args);
      return AdyenSessionResult.fromDynamic(result);
    } on PlatformException catch (e) {
      throw AdyenException.fromPlatform(
        code: e.code,
        message: e.message ?? e.code,
        details: e.details,
      );
    }
  }
}
