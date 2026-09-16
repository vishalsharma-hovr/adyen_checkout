package dev.adyen_checkout.adyen_checkout

import android.app.Activity
import androidx.activity.ComponentActivity
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private var channel: MethodChannel? = null
    private var platformViewRegistry: PlatformViewRegistry? = null
    private var binaryMessenger: io.flutter.plugin.common.BinaryMessenger? = null
    private var activity: Activity? = null
    private var googlePayManager: AdyenGooglePayManager? = null
    private var cardFactoryRegistered = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binaryMessenger = flutterPluginBinding.binaryMessenger
        platformViewRegistry = flutterPluginBinding.platformViewRegistry
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dev.adyen_checkout/wallet")
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startGooglePay" -> startGooglePay(call, result)
            else -> result.notImplemented()
        }
    }

    private fun startGooglePay(call: MethodCall, result: Result) {
        val fragmentActivity = activity as? FragmentActivity
        val manager = googlePayManager
        if (fragmentActivity == null || manager == null) {
            result.error("MISSING_CONFIG", "Activity not ready for Google Pay", null)
            return
        }

        val sessionId = call.argument<String>("sessionId")
            ?: return result.error("MISSING_PARAM", "sessionId missing", null)
        val sessionData = call.argument<String>("sessionData")
            ?: return result.error("MISSING_PARAM", "sessionData missing", null)
        val merchantAccount = call.argument<String>("merchantAccount")
            ?: return result.error("MISSING_PARAM", "merchantAccount missing", null)
        val environment = call.argument<String>("environment")
            ?: return result.error("MISSING_PARAM", "environment missing", null)
        val merchantName = call.argument<String>("googlePayMerchantName")
            ?: call.argument<String>("merchantName")
            ?: return result.error("MISSING_PARAM", "merchantName missing", null)

        @Suppress("UNCHECKED_CAST")
        val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
        val clientKey = resolveClientKey(args, fragmentActivity)
        if (clientKey.isBlank()) {
            result.error("MISSING_CLIENT_KEY", "clientKey is empty", null)
            return
        }

        manager.startGooglePay(
            sessionId,
            sessionData,
            clientKey,
            merchantAccount,
            merchantName,
            environment,
            result,
        )

        val sheet = GooglePayBottomSheet.newInstance(
            manager = manager,
            onDismissedByUser = { manager.onUserDismissed() },
        )
        sheet.show(fragmentActivity.supportFragmentManager, "GooglePayBottomSheet")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        binaryMessenger = null
        platformViewRegistry = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        val componentActivity = binding.activity as? ComponentActivity ?: return
        googlePayManager = AdyenGooglePayManager(componentActivity)
        registerCardFactory(componentActivity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        googlePayManager = null
        cardFactoryRegistered = false
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
        googlePayManager = null
        cardFactoryRegistered = false
    }

    private fun registerCardFactory(activity: ComponentActivity) {
        if (cardFactoryRegistered) return
        val messenger = binaryMessenger ?: return
        val registry = platformViewRegistry ?: return
        registry.registerViewFactory(
            "dev.adyen_checkout/card_view",
            AdyenCardViewFactory(messenger, activity),
        )
        cardFactoryRegistered = true
    }
}
