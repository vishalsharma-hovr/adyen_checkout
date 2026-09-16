import Foundation
import UIKit
import Flutter
import Adyen

final class AdyenCardViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let viewControllerProvider: () -> UIViewController?

    init(messenger: FlutterBinaryMessenger, viewControllerProvider: @escaping () -> UIViewController?) {
        self.messenger = messenger
        self.viewControllerProvider = viewControllerProvider
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        return AdyenCardPlatformView(
            frame: frame,
            viewId: viewId,
            params: params,
            messenger: messenger,
            parentViewController: viewControllerProvider()
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

final class AdyenCardPlatformView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let channel: FlutterMethodChannel
    private weak var parentVC: UIViewController?

    private var session: AdyenSession?
    private var cardComponent: CardComponent?
    private var childVC: UIViewController?

    init(
        frame: CGRect,
        viewId: Int64,
        params: [String: Any],
        messenger: FlutterBinaryMessenger,
        parentViewController: UIViewController?
    ) {
        self.channel = FlutterMethodChannel(
            name: "dev.adyen_checkout/card_view_\(viewId)",
            binaryMessenger: messenger
        )
        self.parentVC = parentViewController
        super.init()
        startCardFlow(params: params)
    }

    func view() -> UIView { container }

    private func startCardFlow(params: [String: Any]) {
        guard
            let sessionId = params["sessionId"] as? String,
            let environment = params["environment"] as? String,
            let sessionData = params["sessionData"] as? String
        else {
            channel.invokeMethod(
                "onError",
                arguments: ["message": "Missing parameters (sessionId/environment/sessionData)"]
            )
            return
        }

        let clientKey = resolveClientKey(params: params)
        guard !clientKey.isEmpty else {
            channel.invokeMethod("onError", arguments: ["message": "clientKey is empty"])
            return
        }

        let showsHolderName = params["holderNameRequired"] as? Bool ?? false
        let showsStoreField = params["storePaymentFieldVisible"] as? Bool ?? true

        guard let env = resolveAdyenEnvironment(environment) else {
            channel.invokeMethod("onError", arguments: ["message": "Unknown environment \(environment)"])
            return
        }

        do {
            let apiContext = try APIContext(environment: env, clientKey: clientKey)
            let adyenContext = AdyenContext(apiContext: apiContext, payment: nil)
            let config = AdyenSession.Configuration(
                sessionIdentifier: sessionId,
                initialSessionData: sessionData,
                context: adyenContext
            )

            AdyenSession.initialize(
                with: config,
                delegate: self,
                presentationDelegate: self,
                completion: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case let .success(adyenSession):
                        self.session = adyenSession
                        let methods = adyenSession.sessionContext.paymentMethods
                        if let cardMethod = methods.paymentMethod(
                            ofType: CardPaymentMethod.self,
                            where: { $0.type == .scheme }
                        ) {
                            var cardConfig = CardComponent.Configuration()
                            cardConfig.showsHolderNameField = showsHolderName
                            cardConfig.showsStorePaymentMethodField = showsStoreField

                            let cardComponent = CardComponent(
                                paymentMethod: cardMethod,
                                context: adyenContext,
                                configuration: cardConfig
                            )
                            self.cardComponent = cardComponent
                            cardComponent.delegate = adyenSession
                            self.embed(componentVC: cardComponent.viewController)
                            self.channel.invokeMethod("onLoaded", arguments: nil)
                        } else {
                            self.channel.invokeMethod(
                                "onError",
                                arguments: ["message": "Card method not available"]
                            )
                        }
                    case let .failure(error):
                        self.channel.invokeMethod(
                            "onError",
                            arguments: ["message": error.localizedDescription]
                        )
                    }
                }
            )
        } catch {
            channel.invokeMethod("onError", arguments: ["message": error.localizedDescription])
        }
    }

    private func embed(componentVC: UIViewController) {
        guard let parent = parentVC else { return }

        if let existing = childVC {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
        }

        childVC = componentVC
        parent.addChild(componentVC)
        container.addSubview(componentVC.view)
        componentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            componentVC.view.topAnchor.constraint(equalTo: container.topAnchor),
            componentVC.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            componentVC.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            componentVC.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        componentVC.didMove(toParent: parent)
    }
}

extension AdyenCardPlatformView: AdyenSessionDelegate {
    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
        channel.invokeMethod("onFinished", arguments: [
            "resultCode": result.resultCode.rawValue,
        ])
    }

    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        channel.invokeMethod("onError", arguments: ["message": error.localizedDescription])
    }
}

extension AdyenCardPlatformView: PresentationDelegate {
    func present(component: any Adyen.PresentableComponent) {
        guard let parent = parentVC else { return }
        parent.present(component.viewController, animated: true)
    }
}

func resolveClientKey(params: [String: Any]) -> String {
    if let key = params["clientKey"] as? String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
    }
    return (Bundle.main.object(forInfoDictionaryKey: "ADYEN_CLIENT_KEY") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func resolveAdyenEnvironment(_ environment: String) -> Environment? {
    switch environment.lowercased() {
    case "test": return .test
    case "us", "united_states", "unitedstates": return .liveUnitedStates
    case "eu", "europe": return .liveEurope
    case "au", "australia": return .liveAustralia
    case "in", "india": return .liveIndia
    case "apse": return .liveApse
    default: return nil
    }
}
