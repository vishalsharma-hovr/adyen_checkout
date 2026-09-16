package dev.adyen_checkout.adyen_checkout

import com.adyen.checkout.core.Environment
import com.google.android.gms.wallet.WalletConstants

internal data class AdyenGooglePayEnvironments(
    val adyen: Environment,
    val googlePay: Int,
)

internal fun resolveAdyenEnvironment(envString: String?): Environment {
    return when (envString.orEmpty().trim().lowercase()) {
        "test" -> Environment.TEST
        "us", "united_states", "unitedstates" -> Environment.UNITED_STATES
        "europe", "eu" -> Environment.EUROPE
        "australia", "au" -> Environment.AUSTRALIA
        "india", "in" -> Environment.INDIA
        "apse" -> Environment.APSE
        else -> throw IllegalArgumentException("Unknown Adyen environment: $envString")
    }
}

internal fun resolveAdyenGooglePayEnvironments(envString: String?): AdyenGooglePayEnvironments {
    val adyen = resolveAdyenEnvironment(envString)
    val googlePay = if (adyen == Environment.TEST) {
        WalletConstants.ENVIRONMENT_TEST
    } else {
        WalletConstants.ENVIRONMENT_PRODUCTION
    }
    return AdyenGooglePayEnvironments(adyen, googlePay)
}

internal fun resolveClientKey(params: Map<String, Any?>, activityContext: android.content.Context): String {
    val fromParams = params["clientKey"]?.toString()?.trim().orEmpty()
    if (fromParams.isNotEmpty()) return fromParams
    return try {
        val ai = activityContext.packageManager.getApplicationInfo(
            activityContext.packageName,
            android.content.pm.PackageManager.GET_META_DATA,
        )
        ai.metaData?.getString("ADYEN_CLIENT_KEY")?.trim().orEmpty()
    } catch (_: Exception) {
        ""
    }
}
