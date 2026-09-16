import 'package:flutter/widgets.dart';

import 'adyen_checkout_platform.dart';
import 'config/adyen_config.dart';
import 'config/adyen_config_exception.dart';
import 'models/adyen_exception.dart';
import 'models/adyen_session_result.dart';
import 'ui/adyen_card_drop_in.dart';

/// Public facade for Adyen Sessions card / Google Pay / Apple Pay.
class AdyenCheckout {
  AdyenCheckout._();

  static AdyenConfig? _config;

  static AdyenConfig get config {
    final c = _config;
    if (c == null) {
      throw AdyenException(
        code: AdyenExceptionCode.missingConfig,
        message: 'Call AdyenCheckout.initialize(...) before using checkout APIs.',
      );
    }
    return c;
  }

  static bool get isInitialized => _config != null;

  static Future<void> initialize(AdyenConfig config) async {
    if (config.clientKey.trim().isEmpty) {
      throw AdyenException(
        code: AdyenExceptionCode.missingClientKey,
        message: 'clientKey is empty after config load / overlay.',
      );
    }
    _config = config;
  }

  static Future<void> initializeFromAsset([String? assetPath]) async {
    await initialize(await AdyenConfig.fromAsset(assetPath));
  }

  /// Shows a modal bottom sheet hosting the native card component.
  static Future<AdyenSessionResult?> startCardDropIn(
    BuildContext context, {
    required String sessionId,
    required String sessionData,
    AdyenConfig? config,
  }) {
    return showAdyenCardDropIn(
      context,
      config: config ?? AdyenCheckout.config,
      sessionId: sessionId,
      sessionData: sessionData,
    );
  }

  static Future<AdyenSessionResult> startGooglePay({
    required String sessionId,
    required String sessionData,
    int? amountMinorUnits,
    AdyenConfig? config,
  }) {
    final resolved = config ?? AdyenCheckout.config;
    _requireClientKey(resolved);
    return AdyenCheckoutPlatform.instance.startGooglePay(
      config: resolved,
      sessionId: sessionId,
      sessionData: sessionData,
      amountMinorUnits: amountMinorUnits,
    );
  }

  static Future<AdyenSessionResult> startApplePay({
    required String sessionId,
    required String sessionData,
    AdyenConfig? config,
  }) {
    final resolved = config ?? AdyenCheckout.config;
    _requireClientKey(resolved);
    if (resolved.applePay.merchantIdentifier.isEmpty) {
      throw AdyenException(
        code: AdyenExceptionCode.missingConfig,
        message: 'applePay.merchantIdentifier is required for Apple Pay.',
      );
    }
    return AdyenCheckoutPlatform.instance.startApplePay(
      config: resolved,
      sessionId: sessionId,
      sessionData: sessionData,
    );
  }

  static void _requireClientKey(AdyenConfig config) {
    if (config.clientKey.trim().isEmpty) {
      throw AdyenConfigException('clientKey is required');
    }
  }
}
