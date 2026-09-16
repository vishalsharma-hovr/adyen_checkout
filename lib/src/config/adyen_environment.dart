/// Adyen live / test environment identifiers used in config JSON and native SDKs.
enum AdyenEnvironment {
  test,
  unitedStates,
  europe,
  australia,
  india,
  apse,
}

extension AdyenEnvironmentCodec on AdyenEnvironment {
  /// Wire value sent to native (`test` | `US` | `EU` | `AU` | `IN` | `APSE`).
  String get wireValue {
    switch (this) {
      case AdyenEnvironment.test:
        return 'test';
      case AdyenEnvironment.unitedStates:
        return 'US';
      case AdyenEnvironment.europe:
        return 'EU';
      case AdyenEnvironment.australia:
        return 'AU';
      case AdyenEnvironment.india:
        return 'IN';
      case AdyenEnvironment.apse:
        return 'APSE';
    }
  }

  static AdyenEnvironment parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'test':
        return AdyenEnvironment.test;
      case 'us':
      case 'united_states':
      case 'unitedstates':
        return AdyenEnvironment.unitedStates;
      case 'eu':
      case 'europe':
        return AdyenEnvironment.europe;
      case 'au':
      case 'australia':
        return AdyenEnvironment.australia;
      case 'in':
      case 'india':
        return AdyenEnvironment.india;
      case 'apse':
        return AdyenEnvironment.apse;
      default:
        throw FormatException('Unknown Adyen environment: $raw');
    }
  }
}
