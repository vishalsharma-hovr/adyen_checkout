package dev.adyen_checkout.adyen_checkout

import android.content.Context
import android.view.View
import androidx.activity.ComponentActivity
import androidx.appcompat.view.ContextThemeWrapper
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.savedstate.SavedStateRegistryOwner
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.card.card
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionPaymentResult
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.util.UUID

class AdyenCardViewFactory(
    private val messenger: BinaryMessenger,
    private val activity: ComponentActivity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = (args as? Map<String, Any?>) ?: emptyMap()
        return AdyenCardPlatformView(
            activity = activity,
            messenger = messenger,
            id = viewId,
            params = params,
        )
    }
}

class AdyenCardPlatformView(
    private val activity: ComponentActivity,
    messenger: BinaryMessenger,
    id: Int,
    params: Map<String, Any?>,
) : PlatformView {

    private val themedContext = ContextThemeWrapper(activity, R.style.AdyenComponentTheme)
    private val componentView = AdyenComponentView(themedContext)
    private val channel = MethodChannel(messenger, "dev.adyen_checkout/card_view_$id")
    private val scope = MainScope()
    private val tempViewModelStoreOwner = object : ViewModelStoreOwner {
        private val store = ViewModelStore()
        override val viewModelStore: ViewModelStore get() = store
    }
    private val componentKey = "CardComponent_${UUID.randomUUID()}"

    init {
        initSession(params)
    }

    private fun initSession(params: Map<String, Any?>) {
        val clientKey = resolveClientKey(params, activity)
        if (clientKey.isBlank()) {
            channel.invokeMethod("onError", mapOf("message" to "clientKey is empty"))
            return
        }
        val envString = params["environment"]?.toString()
        if (envString.isNullOrBlank()) {
            channel.invokeMethod("onError", mapOf("message" to "environment is required"))
            return
        }
        val sessionId = params["sessionId"] as? String
        val sessionData = params["sessionData"] as? String
        if (sessionId.isNullOrBlank() || sessionData.isNullOrBlank()) {
            channel.invokeMethod("onError", mapOf("message" to "sessionId and sessionData are required"))
            return
        }

        val holderNameRequired = params["holderNameRequired"] as? Boolean ?: false
        val storePaymentFieldVisible = params["storePaymentFieldVisible"] as? Boolean ?: true

        val environment = try {
            resolveAdyenEnvironment(envString)
        } catch (e: IllegalArgumentException) {
            channel.invokeMethod("onError", mapOf("message" to (e.message ?: "Invalid environment")))
            return
        }

        val checkoutConfig = CheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
        ) {
            card {
                isHolderNameRequired = holderNameRequired
                isStorePaymentFieldVisible = storePaymentFieldVisible
            }
        }

        scope.launch {
            when (
                val result = CheckoutSessionProvider.createSession(
                    SessionModel(sessionId, sessionData),
                    environment,
                    clientKey,
                )
            ) {
                is CheckoutSessionResult.Success -> {
                    val checkoutSession = result.checkoutSession
                    val paymentMethod: PaymentMethod? =
                        checkoutSession.sessionSetupResponse.paymentMethodsApiResponse
                            ?.paymentMethods
                            ?.firstOrNull { it.type == "scheme" }

                    if (paymentMethod == null) {
                        channel.invokeMethod("onError", mapOf("message" to "Card payment method not available"))
                        return@launch
                    }

                    val cardComponent = CardComponent.PROVIDER.get(
                        activity as SavedStateRegistryOwner,
                        tempViewModelStoreOwner,
                        activity,
                        checkoutSession,
                        paymentMethod,
                        checkoutConfig,
                        activity.application,
                        object : SessionComponentCallback<CardComponentState> {
                            override fun onFinished(result: SessionPaymentResult) {
                                channel.invokeMethod(
                                    "onFinished",
                                    mapOf(
                                        "sessionId" to result.sessionId,
                                        "sessionData" to result.sessionData,
                                        "sessionResult" to result.sessionResult,
                                        "resultCode" to result.resultCode,
                                    ),
                                )
                            }

                            override fun onError(componentError: ComponentError) {
                                channel.invokeMethod(
                                    "onError",
                                    mapOf("message" to (componentError.exception.message ?: "Component error")),
                                )
                            }

                            override fun onAction(action: Action) {
                                channel.invokeMethod("onAction", mapOf("type" to action.type))
                            }
                        },
                        componentKey,
                    )

                    componentView.attach(cardComponent, activity)
                    channel.invokeMethod("onLoaded", null)
                }

                is CheckoutSessionResult.Error -> {
                    channel.invokeMethod(
                        "onError",
                        mapOf("message" to (result.exception.message ?: "Failed to create session")),
                    )
                }
            }
        }
    }

    override fun getView(): View = componentView

    override fun dispose() {
        scope.cancel()
        tempViewModelStoreOwner.viewModelStore.clear()
    }
}
