import UIKit
import Adyen
import PassKit
import Flutter
import os.log

final class AdyenApplePayHandler: NSObject {
    private let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "adyen_checkout",
        category: "AdyenApplePay"
    )

    private weak var parentVC: UIViewController?
    private var flutterResult: FlutterResult?
    private var session: AdyenSession?
    private var applePayComponent: ApplePayComponent?

    init(parentVC: UIViewController, flutterResult: @escaping FlutterResult) {
        self.parentVC = parentVC
        self.flutterResult = flutterResult
        super.init()
    }

    func start(params: [String: Any]) {
        guard
            let sessionId = params["sessionId"] as? String,
            let sessionData = params["sessionData"] as? String,
            let environment = params["environment"] as? String
        else {
            flutterResult?(FlutterError(
                code: "MISSING_PARAMS",
                message: "Missing required parameters: sessionId, sessionData, environment",
                details: nil
            ))
            flutterResult = nil
            return
        }

        let clientKey = resolveClientKey(params: params)
        guard !clientKey.isEmpty else {
            flutterResult?(FlutterError(
                code: "MISSING_CLIENT_KEY",
                message: "clientKey is empty",
                details: nil
            ))
            flutterResult = nil
            return
        }

        guard let env = resolveAdyenEnvironment(environment) else {
            flutterResult?(FlutterError(
                code: "MISSING_PARAMS",
                message: "Unknown environment \(environment)",
                details: nil
            ))
            flutterResult = nil
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
                presentationDelegate: self
            ) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let adyenSession):
                    self.session = adyenSession
                    self.buildAndPresent(session: adyenSession, context: adyenContext, params: params)
                case .failure(let error):
                    self.flutterResult?(FlutterError(
                        code: "SESSION_INIT_FAILED",
                        message: "AdyenSession initialization failed",
                        details: error.localizedDescription
                    ))
                    self.flutterResult = nil
                }
            }
        } catch {
            flutterResult?(FlutterError(
                code: "API_CONTEXT_FAILED",
                message: "Failed to build APIContext",
                details: error.localizedDescription
            ))
            flutterResult = nil
        }
    }

    private func buildAndPresent(session: AdyenSession, context: AdyenContext, params: [String: Any]) {
        let methods = session.sessionContext.paymentMethods
        guard let applePayMethod = methods.paymentMethod(ofType: ApplePayPaymentMethod.self) else {
            flutterResult?(FlutterError(
                code: "METHOD_NOT_FOUND",
                message: "Apple Pay is not available in the payment methods returned by the session",
                details: nil
            ))
            flutterResult = nil
            return
        }

        do {
            let applePayConfig = try buildApplePayConfig(
                params: params,
                sessionAmount: session.sessionContext.amount
            )
            let component = try ApplePayComponent(
                paymentMethod: applePayMethod,
                context: context,
                configuration: applePayConfig
            )
            component.delegate = session
            component.authorizationDelegate = self
            applePayComponent = component

            DispatchQueue.main.async { [weak self] in
                guard let self, let parent = self.parentVC else {
                    self?.flutterResult?(FlutterError(
                        code: "PRESENTER_NIL",
                        message: "parentVC is nil",
                        details: nil
                    ))
                    self?.flutterResult = nil
                    return
                }
                parent.present(component.viewController, animated: true)
            }
        } catch {
            flutterResult?(FlutterError(
                code: "NOT_SUPPORTED",
                message: "Apple Pay is not supported",
                details: error.localizedDescription
            ))
            flutterResult = nil
        }
    }

    private func buildApplePayConfig(
        params: [String: Any],
        sessionAmount: Amount
    ) throws -> ApplePayComponent.Configuration {
        guard
            let merchantId = params["merchantIdentifier"] as? String,
            let merchantName = params["merchantName"] as? String,
            let countryCode = params["countryCode"] as? String
        else {
            throw NSError(domain: "ApplePay", code: 0, userInfo: [
                NSLocalizedDescriptionKey:
                    "Missing Apple Pay parameters: merchantIdentifier, merchantName, countryCode",
            ])
        }

        let currencyCode = sessionAmount.currencyCode
        let amountValue = sessionAmount.value
        let decimalPlaces = ["JPY", "KRW", "VND"].contains(currencyCode.uppercased()) ? 0 : 2
        let divisor = (0..<decimalPlaces).reduce(Decimal(1)) { acc, _ in acc * 10 }
        let decimalAmount = NSDecimalNumber(decimal: Decimal(amountValue) / divisor)
        let summaryItem = PKPaymentSummaryItem(label: merchantName, amount: decimalAmount)
        let applePayPayment = try ApplePayPayment(
            countryCode: countryCode,
            currencyCode: currencyCode,
            summaryItems: [summaryItem]
        )
        return ApplePayComponent.Configuration(
            payment: applePayPayment,
            merchantIdentifier: merchantId
        )
    }

    private func sendResult(_ value: [String: Any]) {
        guard flutterResult != nil else { return }
        flutterResult?(value)
        flutterResult = nil
    }
}

extension AdyenApplePayHandler: AdyenSessionDelegate {
    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.parentVC?.presentedViewController?.dismiss(animated: true) {
                self.sendResult(["resultCode": result.resultCode.rawValue])
            }
        }
    }

    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.parentVC?.presentedViewController?.dismiss(animated: true) {
                self.flutterResult?(FlutterError(
                    code: "CANCELLED",
                    message: "Apple Pay was cancelled",
                    details: error.localizedDescription
                ))
                self.flutterResult = nil
            }
        }
    }
}

extension AdyenApplePayHandler: PresentationDelegate {
    func present(component: any PresentableComponent) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let parent = self.parentVC else {
                self?.flutterResult?(FlutterError(
                    code: "PRESENTER_NIL",
                    message: "PresentationDelegate — parentVC is nil",
                    details: nil
                ))
                self?.flutterResult = nil
                return
            }
            parent.present(component.viewController, animated: true)
        }
    }
}

extension AdyenApplePayHandler: ApplePayAuthorizationDelegate {
    func didAuthorize(payment: PKPayment, completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
}
