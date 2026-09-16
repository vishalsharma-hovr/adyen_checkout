package dev.adyen_checkout.adyen_checkout

sealed class SessionsGooglePayState {
    data object Loading : SessionsGooglePayState()
    data object ShowButton : SessionsGooglePayState()
    data class FinalResult(
        val resultCode: String,
        val sessionId: String?,
        val sessionData: String?,
    ) : SessionsGooglePayState()

    data class Error(val code: String, val message: String) : SessionsGooglePayState()
}
