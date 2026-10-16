import Flutter
import UIKit
import Adyen
#if canImport(AdyenActions)
import AdyenActions
#endif
#if canImport(AdyenCard)
import AdyenCard
#endif
#if canImport(AdyenComponents)
import AdyenComponents
#endif
#if canImport(AdyenSession)
import AdyenSession
#endif

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    private weak var registrar: FlutterPluginRegistrar?
    private var applePayHandler: AdyenApplePayHandler?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = AdyenCheckoutPlugin()
        instance.registrar = registrar

        let channel = FlutterMethodChannel(
            name: "dev.adyen_checkout/wallet",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)

        let factory = AdyenCardViewFactory(
            messenger: registrar.messenger(),
            viewControllerProvider: {
                instance.topViewController()
            }
        )
        registrar.register(factory, withId: "dev.adyen_checkout/card_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startApplePay":
            guard let params = call.arguments as? [String: Any] else {
                result(FlutterError(code: "MISSING_PARAMS", message: "Invalid arguments", details: nil))
                return
            }
            guard let root = topViewController() else {
                result(FlutterError(code: "PRESENTER_NIL", message: "No root view controller", details: nil))
                return
            }
            let handler = AdyenApplePayHandler(parentVC: root, flutterResult: result)
            applePayHandler = handler
            handler.start(params: params)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
