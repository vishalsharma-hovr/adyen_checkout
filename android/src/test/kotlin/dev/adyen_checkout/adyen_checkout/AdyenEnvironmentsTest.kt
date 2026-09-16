package dev.adyen_checkout.adyen_checkout

import com.adyen.checkout.core.Environment
import com.google.android.gms.wallet.WalletConstants
import org.junit.Assert.assertEquals
import org.junit.Test

class AdyenEnvironmentsTest {
    @Test
    fun resolveTestEnvironment() {
        val envs = resolveAdyenGooglePayEnvironments("test")
        assertEquals(Environment.TEST, envs.adyen)
        assertEquals(WalletConstants.ENVIRONMENT_TEST, envs.googlePay)
    }

    @Test
    fun resolveUsEnvironment() {
        val envs = resolveAdyenGooglePayEnvironments("US")
        assertEquals(Environment.UNITED_STATES, envs.adyen)
        assertEquals(WalletConstants.ENVIRONMENT_PRODUCTION, envs.googlePay)
    }
}
