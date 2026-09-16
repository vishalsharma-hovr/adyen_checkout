/// Typed failures from Adyen checkout flows.
enum AdyenExceptionCode {
  cancelled,
  userDismissed,
  missingConfig,
  missingClientKey,
  googlePayUnavailable,
  sessionError,
  notSupported,
  unknown,
}

class AdyenException implements Exception {
  AdyenException({
    required this.code,
    required this.message,
    this.details,
  });

  final AdyenExceptionCode code;
  final String message;
  final Object? details;

  factory AdyenException.fromPlatform({
    required String code,
    required String message,
    Object? details,
  }) {
    return AdyenException(
      code: _mapCode(code),
      message: message,
      details: details,
    );
  }

  static AdyenExceptionCode _mapCode(String code) {
    switch (code.toUpperCase()) {
      case 'CANCELLED':
        return AdyenExceptionCode.cancelled;
      case 'USER_DISMISSED':
        return AdyenExceptionCode.userDismissed;
      case 'MISSING_CONFIG':
      case 'MISSING_PARAM':
      case 'MISSING_PARAMS':
        return AdyenExceptionCode.missingConfig;
      case 'MISSING_CLIENT_KEY':
        return AdyenExceptionCode.missingClientKey;
      case 'GOOGLE_PAY_UNAVAILABLE':
      case 'NO_GOOGLE_PAY':
        return AdyenExceptionCode.googlePayUnavailable;
      case 'SESSION_ERROR':
      case 'SESSION_INIT_FAILED':
        return AdyenExceptionCode.sessionError;
      case 'NOT_SUPPORTED':
        return AdyenExceptionCode.notSupported;
      default:
        return AdyenExceptionCode.unknown;
    }
  }

  @override
  String toString() => 'AdyenException($code): $message';
}
