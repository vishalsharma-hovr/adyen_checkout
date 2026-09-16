package dev.adyen_checkout.adyen_checkout

import android.util.Log
import androidx.activity.ComponentActivity
import androidx.compose.runtime.mutableStateOf
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.googlepay.GooglePayCancellationException
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.googlepay.GooglePayUnavailableException
import com.adyen.checkout.googlepay.MerchantInfo
import com.adyen.checkout.googlepay.googlePay
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionPaymentResult
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject

private const val TAG = "AdyenGooglePayManager"

data class GooglePayComponentData(
    val checkoutSession: CheckoutSession,
    val paymentMethod: PaymentMethod,
    val checkoutConfiguration: CheckoutConfiguration,
    val callback: SessionComponentCallback<GooglePayComponentState>,
)

class AdyenGooglePayManager(
    private val activity: ComponentActivity,
) {
    private var methodResult: MethodChannel.Result? = null
    private val scope = MainScope()

    val state = mutableStateOf<SessionsGooglePayState>(SessionsGooglePayState.Loading)
    val componentData = mutableStateOf<GooglePayComponentData?>(null)

    fun startGooglePay(
        sessionId: String,
        sessionData: String,
        clientKey: String,
        merchantAccount: String,
        merchantName: String,
        environment: String,
        result: MethodChannel.Result,
    ) {
        val envs = resolveAdyenGooglePayEnvironments(environment)
        methodResult = result
        state.value = SessionsGooglePayState.Loading
        componentData.value = null

        scope.launch {
            when (
                val sessionResult = CheckoutSessionProvider.createSession(
                    SessionModel(sessionId, sessionData),
                    envs.adyen,
                    clientKey,
                )
            ) {
                is CheckoutSessionResult.Error -> {
                    handleError("SESSION_ERROR", sessionResult.exception.message ?: "Failed to create session")
                }

                is CheckoutSessionResult.Success -> {
                    val checkoutSession = sessionResult.checkoutSession
                    val allMethods = checkoutSession
                        .sessionSetupResponse.paymentMethodsApiResponse?.paymentMethods.orEmpty()
                    val paymentMethod = allMethods
                        .firstOrNull { it.type in GooglePayComponent.PAYMENT_METHOD_TYPES }
                        ?: run {
                            handleError("NO_GOOGLE_PAY", "Google Pay not in session")
                            return@launch
                        }

                    val checkoutConfiguration = CheckoutConfiguration(
                        environment = envs.adyen,
                        clientKey = clientKey,
                    ) {
                        googlePay {
                            setGooglePayEnvironment(envs.googlePay)
                            setMerchantAccount(merchantAccount)
                            setMerchantInfo(MerchantInfo(merchantName = merchantName))
                            setSubmitButtonVisible(false)
                        }
                    }

                    val sessionCallback = object : SessionComponentCallback<GooglePayComponentState> {
                        override fun onFinished(result: SessionPaymentResult) {
                            state.value = SessionsGooglePayState.FinalResult(
                                resultCode = result.resultCode ?: "",
                                sessionId = result.sessionId,
                                sessionData = result.sessionData,
                            )
                            sendSuccess(
                                JSONObject().apply {
                                    put("resultCode", result.resultCode)
                                    put("sessionId", result.sessionId)
                                    put("sessionData", result.sessionData)
                                    put("sessionResult", result.sessionResult)
                                }.toString(),
                            )
                        }

                        override fun onError(componentError: ComponentError) {
                            when (componentError.exception) {
                                is GooglePayUnavailableException ->
                                    handleError("GOOGLE_PAY_UNAVAILABLE", "Google Pay is not available on this device")
                                is GooglePayCancellationException ->
                                    handleError("CANCELLED", "User cancelled Google Pay")
                                else ->
                                    handleError(
                                        "GOOGLE_PAY_ERROR",
                                        componentError.exception.message ?: "Unknown error",
                                    )
                            }
                        }

                        override fun onAction(action: Action) {
                            Log.d(TAG, "onAction type=${action.type}")
                        }
                    }

                    componentData.value = GooglePayComponentData(
                        checkoutSession = checkoutSession,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = checkoutConfiguration,
                        callback = sessionCallback,
                    )
                    state.value = SessionsGooglePayState.ShowButton
                }
            }
        }
    }

    private fun handleError(code: String, message: String) {
        state.value = SessionsGooglePayState.Error(code, message)
        methodResult?.error(code, message, null)
        methodResult = null
    }

    private fun sendSuccess(data: String) {
        methodResult?.success(data)
        methodResult = null
    }

    fun onUserDismissed() {
        methodResult?.error("USER_DISMISSED", "User dismissed Google Pay", null)
        methodResult = null
    }
}
