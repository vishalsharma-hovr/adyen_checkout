/// Method channel and platform-view identifiers.
abstract final class AdyenCheckoutChannels {
  static const String wallet = 'dev.adyen_checkout/wallet';
  static const String cardViewType = 'dev.adyen_checkout/card_view';

  static String cardViewEvents(int viewId) =>
      'dev.adyen_checkout/card_view_$viewId';
}
