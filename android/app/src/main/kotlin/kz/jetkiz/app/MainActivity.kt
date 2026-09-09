package kz.jetkiz.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val PAYMENT_RETURN_CHANNEL = "kz.jetkiz.app/payment-return"
    }

    private var paymentReturnChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        paymentReturnChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PAYMENT_RETURN_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialPaymentReturn" -> result.success(paymentReturnUri(intent))
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val paymentReturn = paymentReturnUri(intent) ?: return
        paymentReturnChannel?.invokeMethod("paymentReturn", paymentReturn)
    }

    private fun paymentReturnUri(intent: Intent?): String? {
        val uri: Uri = intent?.data ?: return null
        if (!uri.scheme.equals("jetkiz", ignoreCase = true)) return null
        if (!uri.host.equals("payment", ignoreCase = true)) return null
        if (uri.path != "/return") return null
        return uri.toString()
    }
}
