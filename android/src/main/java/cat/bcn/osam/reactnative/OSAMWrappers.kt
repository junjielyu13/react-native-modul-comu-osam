package cat.bcn.osam.reactnative

import android.content.Context
import cat.bcn.commonmodule.analytics.AnalyticsWrapper
import cat.bcn.commonmodule.crashlytics.CrashlyticsWrapper
import cat.bcn.commonmodule.messaging.MessagingWrapper
import cat.bcn.commonmodule.performance.PerformanceWrapper
import cat.bcn.commonmodule.platform.PlatformUtil

/**
 * Container for the five wrappers OSAMCommons needs.
 *
 * Pass a custom factory to [OSAMPackage] to override the defaults.
 * Defaults are Firebase-backed — see [DefaultOSAMWrappersFactory].
 */
data class OSAMWrappers(
  val crashlytics: CrashlyticsWrapper,
  val performance: PerformanceWrapper,
  val analytics: AnalyticsWrapper,
  val platformUtil: PlatformUtil,
  val messaging: MessagingWrapper,
  val backendEndpoint: String,
)

fun interface OSAMWrappersFactory {
  fun create(context: Context): OSAMWrappers
}
