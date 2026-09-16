import 'dart:convert';

import 'package:flutter/services.dart';

import 'adyen_config_exception.dart';
import 'adyen_environment.dart';

/// Apple Pay settings from config JSON.
class AdyenApplePayConfig {
  const AdyenApplePayConfig({required this.merchantIdentifier});

  final String merchantIdentifier;

  factory AdyenApplePayConfig.fromMap(Map<String, dynamic> map) {
    final id = map['merchantIdentifier']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw AdyenConfigException('applePay.merchantIdentifier is required');
    }
    return AdyenApplePayConfig(merchantIdentifier: id);
  }

  Map<String, dynamic> toMap() => {'merchantIdentifier': merchantIdentifier};
}

/// Google Pay settings from config JSON.
class AdyenGooglePayConfig {
  const AdyenGooglePayConfig({
    required this.merchantName,
    this.allowedCardNetworks = const [
      'AMEX',
      'DISCOVER',
      'JCB',
      'MASTERCARD',
      'VISA',
    ],
  });

  final String merchantName;
  final List<String> allowedCardNetworks;

  factory AdyenGooglePayConfig.fromMap(Map<String, dynamic> map) {
    final name = map['merchantName']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw AdyenConfigException('googlePay.merchantName is required');
    }
    final networks = map['allowedCardNetworks'];
    return AdyenGooglePayConfig(
      merchantName: name,
      allowedCardNetworks: networks is List
          ? networks.map((e) => e.toString()).toList()
          : const ['AMEX', 'DISCOVER', 'JCB', 'MASTERCARD', 'VISA'],
    );
  }

  Map<String, dynamic> toMap() => {
        'merchantName': merchantName,
        'allowedCardNetworks': allowedCardNetworks,
      };
}

/// Card component UI flags from config JSON.
class AdyenCardConfig {
  const AdyenCardConfig({
    this.holderNameRequired = false,
    this.storePaymentFieldVisible = true,
  });

  final bool holderNameRequired;
  final bool storePaymentFieldVisible;

  factory AdyenCardConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AdyenCardConfig();
    return AdyenCardConfig(
      holderNameRequired: map['holderNameRequired'] == true,
      storePaymentFieldVisible: map['storePaymentFieldVisible'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'holderNameRequired': holderNameRequired,
        'storePaymentFieldVisible': storePaymentFieldVisible,
      };
}

/// App-owned Adyen configuration (loaded from JSON assets).
class AdyenConfig {
  const AdyenConfig({
    required this.clientKey,
    required this.environment,
    required this.merchantAccount,
    required this.merchantName,
    required this.countryCode,
    required this.currencyCode,
    required this.shopperLocale,
    required this.applePay,
    required this.googlePay,
    this.card = const AdyenCardConfig(),
  });

  final String clientKey;
  final AdyenEnvironment environment;
  final String merchantAccount;
  final String merchantName;
  final String countryCode;
  final String currencyCode;
  final String shopperLocale;
  final AdyenApplePayConfig applePay;
  final AdyenGooglePayConfig googlePay;
  final AdyenCardConfig card;

  /// Default asset path; override with `--dart-define=ADYEN_CONFIG_ASSET=...`.
  static const String defaultAssetPath = 'assets/adyen/adyen_config.json';

  static String resolveAssetPath({String? assetPath}) {
    const fromDefine = String.fromEnvironment('ADYEN_CONFIG_ASSET', defaultValue: '');
    if (assetPath != null && assetPath.isNotEmpty) return assetPath;
    if (fromDefine.isNotEmpty) return fromDefine;
    return defaultAssetPath;
  }

  /// Loads JSON from a Flutter asset, then applies optional `ADYEN_CLIENT_KEY` overlay.
  static Future<AdyenConfig> fromAsset([String? assetPath]) async {
    final path = resolveAssetPath(assetPath: assetPath);
    final raw = await rootBundle.loadString(path);
    return fromJson(raw).withClientKeyOverlay();
  }

  static AdyenConfig fromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw AdyenConfigException('Config root must be a JSON object');
    }
    return fromMap(Map<String, dynamic>.from(decoded));
  }

  static AdyenConfig fromMap(Map<String, dynamic> map) {
    String require(String key) {
      final v = map[key]?.toString().trim() ?? '';
      if (v.isEmpty) throw AdyenConfigException('$key is required');
      return v;
    }

    final envRaw = require('environment');
    final appleRaw = map['applePay'];
    final googleRaw = map['googlePay'];
    if (appleRaw is! Map) {
      throw AdyenConfigException('applePay object is required');
    }
    if (googleRaw is! Map) {
      throw AdyenConfigException('googlePay object is required');
    }

    final cardRaw = map['card'];
    return AdyenConfig(
      clientKey: require('clientKey'),
      environment: AdyenEnvironmentCodec.parse(envRaw),
      merchantAccount: require('merchantAccount'),
      merchantName: require('merchantName'),
      countryCode: require('countryCode'),
      currencyCode: require('currencyCode'),
      shopperLocale: map['shopperLocale']?.toString().trim().isNotEmpty == true
          ? map['shopperLocale'].toString().trim()
          : 'en-US',
      applePay: AdyenApplePayConfig.fromMap(Map<String, dynamic>.from(appleRaw)),
      googlePay: AdyenGooglePayConfig.fromMap(Map<String, dynamic>.from(googleRaw)),
      card: AdyenCardConfig.fromMap(
        cardRaw is Map ? Map<String, dynamic>.from(cardRaw) : null,
      ),
    );
  }

  /// Prefer `--dart-define=ADYEN_CLIENT_KEY=...` when non-empty.
  AdyenConfig withClientKeyOverlay() {
    const overlay = String.fromEnvironment('ADYEN_CLIENT_KEY', defaultValue: '');
    if (overlay.trim().isEmpty) return this;
    return copyWith(clientKey: overlay.trim());
  }

  AdyenConfig copyWith({
    String? clientKey,
    AdyenEnvironment? environment,
    String? merchantAccount,
    String? merchantName,
    String? countryCode,
    String? currencyCode,
    String? shopperLocale,
    AdyenApplePayConfig? applePay,
    AdyenGooglePayConfig? googlePay,
    AdyenCardConfig? card,
  }) {
    return AdyenConfig(
      clientKey: clientKey ?? this.clientKey,
      environment: environment ?? this.environment,
      merchantAccount: merchantAccount ?? this.merchantAccount,
      merchantName: merchantName ?? this.merchantName,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      shopperLocale: shopperLocale ?? this.shopperLocale,
      applePay: applePay ?? this.applePay,
      googlePay: googlePay ?? this.googlePay,
      card: card ?? this.card,
    );
  }

  Map<String, dynamic> toCreationParams({
    required String sessionId,
    required String sessionData,
  }) {
    return {
      'clientKey': clientKey,
      'environment': environment.wireValue,
      'merchantAccount': merchantAccount,
      'merchantName': merchantName,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'shopperLocale': shopperLocale,
      'sessionId': sessionId,
      'sessionData': sessionData,
      'holderNameRequired': card.holderNameRequired,
      'storePaymentFieldVisible': card.storePaymentFieldVisible,
      'merchantIdentifier': applePay.merchantIdentifier,
      'googlePayMerchantName': googlePay.merchantName,
      'allowedCardNetworks': googlePay.allowedCardNetworks,
    };
  }

  Map<String, dynamic> toWalletArgs({
    required String sessionId,
    required String sessionData,
    int? amountMinorUnits,
  }) {
    return {
      ...toCreationParams(sessionId: sessionId, sessionData: sessionData),
      if (amountMinorUnits != null) 'amountMinorUnits': amountMinorUnits,
    };
  }
}
