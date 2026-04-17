package com.example

import android.content.Context
import cat.bcn.commonmodule.analytics.AnalyticsWrapper
import cat.bcn.commonmodule.crashlytics.CrashlyticsWrapper
import cat.bcn.commonmodule.messaging.MessagingWrapper
import cat.bcn.commonmodule.performance.PerformanceMetric
import cat.bcn.commonmodule.performance.PerformanceWrapper
import cat.bcn.commonmodule.platform.PlatformUtil
import cat.bcn.osam.reactnative.OSAMWrappers
import cat.bcn.osam.reactnative.OSAMWrappersFactory
import android.util.Log

/**
 * No-op factory used by the example to avoid requiring Firebase setup.
 * Demonstrates the Option 3 override path — real apps should use the
 * default [cat.bcn.osam.reactnative.DefaultOSAMWrappersFactory] or provide
 * their own non-Firebase implementation.
 */
class NoopWrappersFactory : OSAMWrappersFactory {
  override fun create(context: Context): OSAMWrappers = OSAMWrappers(
    crashlytics = NoopCrashlytics,
    performance = NoopPerformance,
    analytics = NoopAnalytics,
    platformUtil = NoopPlatformUtil,
    messaging = NoopMessaging,
    backendEndpoint = "https://dev-osam-modul-comu.dtibcn.cat/",
  )
}

private object NoopCrashlytics : CrashlyticsWrapper {
  override fun recordException(exception: Exception) {
    Log.w("OSAM-Noop", "recordException: ${exception.message}")
  }
}

private object NoopAnalytics : AnalyticsWrapper {
  override fun logEvent(name: String, parameters: Map<String, String>) {
    Log.d("OSAM-Noop", "logEvent: $name $parameters")
  }
}

private object NoopPerformance : PerformanceWrapper {
  override fun createMetric(url: String, httpMethod: String): PerformanceMetric = NoopMetric
}

private object NoopMetric : PerformanceMetric {
  override fun start() {}
  override fun setRequestPayloadSize(bytes: Long) {}
  override fun markRequestComplete() {}
  override fun markResponseStart() {}
  override fun setResponseContentType(contentType: String) {}
  override fun setHttpResponseCode(responseCode: Int) {}
  override fun setResponsePayloadSize(bytes: Long) {}
  override fun putAttribute(attribute: String, value: String) {}
  override fun stop() {}
}

private object NoopPlatformUtil : PlatformUtil {
  override fun encodeUrl(url: String): String = url
  override fun openUrl(url: String): Boolean = false
  override fun getDeviceModelIdentifier(): String = android.os.Build.MODEL ?: ""
}

private object NoopMessaging : MessagingWrapper {
  override suspend fun subscribeToTopic(topic: String) {}
  override suspend fun unsubscribeFromTopic(topic: String) {}
  override suspend fun getToken(): String = "noop-token"
}
