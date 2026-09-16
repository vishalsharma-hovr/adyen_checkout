import 'dart:convert';

/// Normalized session / component result from native Adyen flows.
class AdyenSessionResult {
  const AdyenSessionResult({
    required this.resultCode,
    this.sessionId,
    this.sessionData,
    this.sessionResult,
    this.raw,
  });

  final String resultCode;
  final String? sessionId;
  final String? sessionData;
  final String? sessionResult;
  final Map<String, dynamic>? raw;

  bool get isAuthorised =>
      resultCode.toLowerCase() == 'authorised' ||
      resultCode.toLowerCase() == 'authorized';

  factory AdyenSessionResult.fromDynamic(dynamic value) {
    if (value is AdyenSessionResult) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return AdyenSessionResult.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
      return AdyenSessionResult(resultCode: value);
    }
    if (value is Map) {
      return AdyenSessionResult.fromMap(Map<String, dynamic>.from(value));
    }
    throw FormatException('Unsupported Adyen result payload: $value');
  }

  factory AdyenSessionResult.fromMap(Map<String, dynamic> map) {
    final code = map['resultCode']?.toString() ?? '';
    if (code.isEmpty) {
      throw FormatException('resultCode missing in Adyen result: $map');
    }
    return AdyenSessionResult(
      resultCode: code,
      sessionId: map['sessionId']?.toString(),
      sessionData: map['sessionData']?.toString(),
      sessionResult: map['sessionResult']?.toString(),
      raw: map,
    );
  }

  Map<String, dynamic> toMap() => {
        'resultCode': resultCode,
        if (sessionId != null) 'sessionId': sessionId,
        if (sessionData != null) 'sessionData': sessionData,
        if (sessionResult != null) 'sessionResult': sessionResult,
      };
}
