package cat.bcn.osam.reactnative

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.ContextCompat
import cat.bcn.commonmodule.analytics.AnalyticsWrapper
import cat.bcn.commonmodule.crashlytics.CrashlyticsWrapper
import cat.bcn.commonmodule.messaging.MessagingWrapper
import cat.bcn.commonmodule.performance.PerformanceMetric
import cat.bcn.commonmodule.performance.PerformanceWrapper
import cat.bcn.commonmodule.platform.PlatformUtil
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.perf.FirebasePerformance
import com.google.firebase.perf.metrics.HttpMetric
import kotlinx.coroutines.tasks.await

/**
 * Default [OSAMWrappersFactory] backed by Firebase.
 *
 * Requires the consumer app to declare Firebase Analytics, Crashlytics,
 * Performance and Messaging dependencies (matching the versions bundled
 * by com.google.firebase:firebase-bom in the host app).
 *
 * [backendEndpoint] is read from a string resource named `common_module_endpoint`
 * unless explicitly provided.
 */
class DefaultOSAMWrappersFactory(
  private val backendEndpoint: String? = null,
) : OSAMWrappersFactory {

  override fun create(context: Context): OSAMWrappers = OSAMWrappers(
    crashlytics = FirebaseCrashlyticsWrapper(),
    performance = FirebasePerformanceWrapper(),
    analytics = FirebaseAnalyticsWrapper(context),
    platformUtil = DefaultPlatformUtil(context),
    messaging = FirebaseMessagingWrapper(),
    backendEndpoint = backendEndpoint ?: resolveEndpointFromResources(context),
  )

  private fun resolveEndpointFromResources(context: Context): String {
    val resId = context.resources.getIdentifier(
      "common_module_endpoint",
      "string",
      context.packageName,
    )
    if (resId == 0) {
      error(
        "common_module_endpoint string resource not found. " +
          "Either define <string name=\"common_module_endpoint\">…</string> in the app, " +
          "or pass an explicit endpoint to DefaultOSAMWrappersFactory(backendEndpoint = …)."
      )
    }
    return context.getString(resId)
  }
}

internal class FirebaseCrashlyticsWrapper : CrashlyticsWrapper {
  override fun recordException(exception: Exception) {
    FirebaseCrashlytics.getInstance().recordException(exception)
  }
}

internal class FirebaseAnalyticsWrapper(context: Context) : AnalyticsWrapper {
  private val analytics = FirebaseAnalytics.getInstance(context)

  override fun logEvent(name: String, parameters: Map<String, String>) {
    analytics.logEvent(name, parameters.toBundle())
  }

  private fun Map<String, String>.toBundle(): Bundle = Bundle().apply {
    this@toBundle.forEach { putString(it.key, it.value) }
  }
}

internal class FirebasePerformanceWrapper : PerformanceWrapper {
  override fun createMetric(url: String, httpMethod: String): PerformanceMetric =
    FirebasePerformanceMetric(FirebasePerformance.getInstance().newHttpMetric(url, httpMethod))
}

internal class FirebasePerformanceMetric(private val metric: HttpMetric?) : PerformanceMetric {
  override fun start() { metric?.start() }
  override fun setRequestPayloadSize(bytes: Long) { metric?.setRequestPayloadSize(bytes) }
  override fun markRequestComplete() { metric?.markRequestComplete() }
  override fun markResponseStart() { metric?.markResponseStart() }
  override fun setResponseContentType(contentType: String) { metric?.setResponseContentType(contentType) }
  override fun setHttpResponseCode(responseCode: Int) { metric?.setHttpResponseCode(responseCode) }
  override fun setResponsePayloadSize(bytes: Long) { metric?.setResponsePayloadSize(bytes) }
  override fun putAttribute(attribute: String, value: String) { metric?.putAttribute(attribute, value) }
  override fun stop() { metric?.stop() }
}

internal class DefaultPlatformUtil(private val context: Context) : PlatformUtil {
  override fun encodeUrl(url: String): String = url

  override fun openUrl(url: String): Boolean {
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    ContextCompat.startActivity(context, intent, null)
    return true
  }

  override fun getDeviceModelIdentifier(): String = android.os.Build.MODEL ?: ""
}

internal class FirebaseMessagingWrapper : MessagingWrapper {
  private val messaging = FirebaseMessaging.getInstance()
  override suspend fun subscribeToTopic(topic: String) { messaging.subscribeToTopic(topic) }
  override suspend fun unsubscribeFromTopic(topic: String) { messaging.unsubscribeFromTopic(topic) }
  override suspend fun getToken(): String = messaging.token.await()
}
