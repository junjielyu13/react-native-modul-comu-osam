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
 *
 * When [debug] is `true`, internal failure paths in the default wrappers
 * send breadcrumbs to Crashlytics via `FirebaseCrashlytics.log(...)`.
 * Defaults to `false` so production apps stay silent.
 */
class DefaultOSAMWrappersFactory(
  private val backendEndpoint: String? = null,
  private val debug: Boolean = false,
) : OSAMWrappersFactory {

  override fun create(context: Context): OSAMWrappers = OSAMWrappers(
    crashlytics = FirebaseCrashlyticsWrapper(),
    performance = FirebasePerformanceWrapper(debug),
    analytics = FirebaseAnalyticsWrapper(context),
    platformUtil = DefaultPlatformUtil(context, debug),
    messaging = FirebaseMessagingWrapper(debug),
    backendEndpoint = backendEndpoint ?: resolveEndpointFromResources(context),
  )

  private fun resolveEndpointFromResources(context: Context): String {
    val resId = context.resources.getIdentifier(
      "common_module_endpoint",
      "string",
      context.packageName,
    )
    if (resId == 0) {
      if (debug) {
        FirebaseCrashlytics.getInstance().log(
          "DefaultOSAMWrappersFactory.resolveEndpointFromResources: common_module_endpoint string resource missing"
        )
      }
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

internal class FirebasePerformanceWrapper(private val debug: Boolean) : PerformanceWrapper {
  override fun createMetric(url: String, httpMethod: String): PerformanceMetric {
    if (url.isEmpty()) {
      logFailure("empty URL string", url, httpMethod)
      return FirebasePerformanceMetric(null)
    }
    val uri = Uri.parse(url)
    val scheme = uri.scheme
    if (scheme != "http" && scheme != "https") {
      logFailure("unsupported URL scheme", url, httpMethod)
      return FirebasePerformanceMetric(null)
    }
    val host = uri.host
    if (host.isNullOrEmpty()) {
      logFailure("empty URL host", url, httpMethod)
      return FirebasePerformanceMetric(null)
    }
    val metric = runCatching {
      FirebasePerformance.getInstance().newHttpMetric(url, httpMethod)
    }.getOrNull()
    if (metric == null) {
      logFailure("HttpMetric init returned null", url, httpMethod)
      return FirebasePerformanceMetric(null)
    }
    return FirebasePerformanceMetric(metric)
  }

  private fun logFailure(reason: String, url: String, httpMethod: String) {
    if (!debug) return
    val issue = "FirebasePerformanceWrapper.createMetric: $reason — url=${redactUrl(url)}, httpMethod=$httpMethod"
    val crashlytics = FirebaseCrashlytics.getInstance()
    crashlytics.log(issue)
    crashlytics.recordException(RuntimeException(issue))
  }
}

// Truncates `s` to fit within `maxBytes` UTF-8 bytes, never splitting a
// code point (so the result is always valid UTF-8 / valid Kotlin String).
internal fun truncateUtf8(s: String, maxBytes: Int): String {
  if (s.isEmpty() || maxBytes <= 0) return ""
  val sb = StringBuilder()
  var bytes = 0
  var i = 0
  while (i < s.length) {
    val cp = s.codePointAt(i)
    val cpBytes = when {
      cp < 0x80 -> 1
      cp < 0x800 -> 2
      cp < 0x10000 -> 3
      else -> 4
    }
    if (bytes + cpBytes > maxBytes) break
    sb.appendCodePoint(cp)
    bytes += cpBytes
    i += Character.charCount(cp)
  }
  return sb.toString()
}

// URL query/fragment may carry tokens or PII. Strip down to scheme://host/path
// before logging anywhere off-device (Crashlytics breadcrumbs).
internal fun redactUrl(url: String): String {
  if (url.isEmpty()) return "<empty>"
  return try {
    val u = Uri.parse(url)
    val scheme = u.scheme
    val host = u.host
    if (scheme.isNullOrEmpty() || host.isNullOrEmpty()) "<malformed>"
    else "$scheme://$host${u.path.orEmpty()}"
  } catch (e: Throwable) {
    "<malformed>"
  }
}

internal class FirebasePerformanceMetric(private val metric: HttpMetric?) : PerformanceMetric {
  override fun start() { metric?.start() }
  override fun setRequestPayloadSize(bytes: Long) { metric?.setRequestPayloadSize(bytes) }
  override fun markRequestComplete() { metric?.markRequestComplete() }
  override fun markResponseStart() { metric?.markResponseStart() }
  override fun setResponseContentType(contentType: String) { metric?.setResponseContentType(contentType) }
  override fun setHttpResponseCode(responseCode: Int) { metric?.setHttpResponseCode(responseCode) }
  override fun setResponsePayloadSize(bytes: Long) { metric?.setResponsePayloadSize(bytes) }
  override fun putAttribute(attribute: String, value: String) {
    if (attribute.isEmpty()) return
    // Firebase only accepts ASCII [A-Za-z0-9_], must start with a letter,
    // key ≤ 40 chars, value ≤ 100 chars. Out-of-spec attrs are silently dropped
    // by Firebase, so sanitize here to keep them observable.
    var sanitized = attribute.replace(Regex("[^A-Za-z0-9_]"), "_")
    val first = sanitized.first()
    if (first !in 'a'..'z' && first !in 'A'..'Z') {
      sanitized = "a_$sanitized"
    }
    // Key is ASCII after sanitize → byte count == char count, take(40) safe.
    // Value can hold any Unicode; truncating by char count may split a
    // surrogate pair (Kotlin String is UTF-16) and Firebase enforces the
    // 100-char limit per UTF-8 byte server-side. Truncate by UTF-8 bytes,
    // never splitting a code point.
    metric?.putAttribute(sanitized.take(40), truncateUtf8(value, 100))
  }
  override fun stop() { metric?.stop() }
}

internal class DefaultPlatformUtil(
  private val context: Context,
  private val debug: Boolean,
) : PlatformUtil {
  override fun encodeUrl(url: String): String = url

  override fun openUrl(url: String): Boolean {
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    return try {
      ContextCompat.startActivity(context, intent, null)
      true
    } catch (e: Exception) {
      // ActivityNotFoundException is the common case; SecurityException can
      // fire e.g. when the resolved Activity requires a permission we don't
      // hold. Both surface the same way to JS (return false) — broaden the
      // catch so the app never crashes from a malformed/hostile URL.
      if (debug) {
        val crashlytics = FirebaseCrashlytics.getInstance()
        crashlytics.log(
          "DefaultPlatformUtil.openUrl: failed to start activity — url=${redactUrl(url)}, error=${e.message}"
        )
        crashlytics.recordException(e)
      }
      false
    }
  }

  override fun getDeviceModelIdentifier(): String = android.os.Build.MODEL ?: ""
}

internal class FirebaseMessagingWrapper(private val debug: Boolean) : MessagingWrapper {
  private val messaging = FirebaseMessaging.getInstance()

  override suspend fun subscribeToTopic(topic: String) {
    try {
      messaging.subscribeToTopic(topic).await()
    } catch (e: Exception) {
      if (debug) {
        val crashlytics = FirebaseCrashlytics.getInstance()
        crashlytics.log("FirebaseMessagingWrapper.subscribeToTopic: topic=$topic, error=${e.message}")
        crashlytics.recordException(e)
      }
      throw e
    }
  }

  override suspend fun unsubscribeFromTopic(topic: String) {
    try {
      messaging.unsubscribeFromTopic(topic).await()
    } catch (e: Exception) {
      if (debug) {
        val crashlytics = FirebaseCrashlytics.getInstance()
        crashlytics.log("FirebaseMessagingWrapper.unsubscribeFromTopic: topic=$topic, error=${e.message}")
        crashlytics.recordException(e)
      }
      throw e
    }
  }

  override suspend fun getToken(): String {
    return try {
      messaging.token.await()
    } catch (e: Exception) {
      if (debug) {
        val crashlytics = FirebaseCrashlytics.getInstance()
        crashlytics.log("FirebaseMessagingWrapper.getToken: ${e.message}")
        crashlytics.recordException(e)
      }
      throw e
    }
  }
}
