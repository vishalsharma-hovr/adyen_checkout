package dev.adyen_checkout.adyen_checkout

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import com.adyen.checkout.components.compose.AdyenComponent
import com.adyen.checkout.googlepay.GooglePayComponent
import com.google.android.material.bottomsheet.BottomSheetDialogFragment

class GooglePayBottomSheet : BottomSheetDialogFragment() {

    var manager: AdyenGooglePayManager? = null
    var onDismissedByUser: (() -> Unit)? = null

    companion object {
        fun newInstance(
            manager: AdyenGooglePayManager,
            onDismissedByUser: () -> Unit,
        ) = GooglePayBottomSheet().also {
            it.manager = manager
            it.onDismissedByUser = onDismissedByUser
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        return ComposeView(requireContext()).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
            setContent {
                SessionsGooglePayContent(manager = manager, fragment = this@GooglePayBottomSheet)
            }
        }
    }

    override fun onCancel(dialog: DialogInterface) {
        super.onCancel(dialog)
        onDismissedByUser?.invoke()
    }
}

@Composable
private fun SessionsGooglePayContent(
    manager: AdyenGooglePayManager?,
    fragment: GooglePayBottomSheet,
) {
    if (manager == null) return

    val currentState by manager.state
    val currentComponentData by manager.componentData

    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center,
    ) {
        when (currentState) {
            is SessionsGooglePayState.ShowButton -> {
                currentComponentData?.let { data ->
                    val googlePayComponent = remember(data) { getGooglePayComponent(fragment, data) }
                    LaunchedEffect(googlePayComponent) { googlePayComponent.submit() }
                    AdyenComponent(
                        component = googlePayComponent,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
            is SessionsGooglePayState.FinalResult,
            is SessionsGooglePayState.Error,
            -> {
                LaunchedEffect(Unit) { fragment.dismiss() }
            }
            else -> Unit
        }
    }
}

private fun getGooglePayComponent(
    fragment: GooglePayBottomSheet,
    data: GooglePayComponentData,
): GooglePayComponent {
    return with(data) {
        GooglePayComponent.PROVIDER.get(
            fragment = fragment,
            checkoutSession = checkoutSession,
            paymentMethod = paymentMethod,
            checkoutConfiguration = checkoutConfiguration,
            componentCallback = callback,
            key = "googlepay_component",
        )
    }
}
