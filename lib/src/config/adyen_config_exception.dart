/// Thrown when [AdyenConfig] JSON / map validation fails.
class AdyenConfigException implements Exception {
  AdyenConfigException(this.message);

  final String message;

  @override
  String toString() => 'AdyenConfigException: $message';
}
