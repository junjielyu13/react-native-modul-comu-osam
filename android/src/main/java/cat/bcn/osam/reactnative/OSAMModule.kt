package cat.bcn.osam.reactnative

import cat.bcn.commonmodule.ui.versioncontrol.Language
import cat.bcn.commonmodule.ui.versioncontrol.OSAMCommons
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = OSAMModule.NAME)
class OSAMModule(
  reactContext: ReactApplicationContext,
  private val wrappersFactory: OSAMWrappersFactory,
) : ReactContextBaseJavaModule(reactContext) {

  companion object {
    const val NAME = "OSAMModule"
  }

  private val osamCommons: OSAMCommons by lazy {
    val activity = currentActivity
      ?: error("OSAMCommons requires an Activity. Call OSAM methods after the app is resumed.")
    val wrappers = wrappersFactory.create(reactApplicationContext)
    OSAMCommons(
      activity = activity,
      context = reactApplicationContext,
      backendEndpoint = wrappers.backendEndpoint,
      crashlyticsWrapper = wrappers.crashlytics,
      performanceWrapper = wrappers.performance,
      analyticsWrapper = wrappers.analytics,
      platformUtil = wrappers.platformUtil,
      messagingWrapper = wrappers.messaging,
    )
  }

  override fun getName(): String = NAME

  @ReactMethod
  fun checkVersionControl(languageCode: String, promise: Promise) {
    try {
      osamCommons.versionControl(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("VERSION_CONTROL_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun showRatingDialog(languageCode: String, promise: Promise) {
    try {
      osamCommons.rating(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("RATING_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun getDeviceInformation(promise: Promise) {
    try {
      osamCommons.deviceInformation { response, info ->
        if (response.name == "ACCEPTED" && info != null) {
          promise.resolve(WritableNativeMap().apply {
            putString("platformName", info.platformName)
            putString("platformVersion", info.platformVersion)
            putString("platformModel", info.platformModel)
          })
        } else {
          promise.reject("DEVICE_INFO_ERROR", "Failed to get device information")
        }
      }
    } catch (e: Exception) {
      promise.reject("DEVICE_INFO_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun getAppInformation(promise: Promise) {
    try {
      osamCommons.appInformation { response, info ->
        if (response.name == "ACCEPTED" && info != null) {
          promise.resolve(WritableNativeMap().apply {
            putString("appName", info.appName)
            putString("appVersionName", info.appVersionName)
            putString("appVersionCode", info.appVersionCode)
          })
        } else {
          promise.reject("APP_INFO_ERROR", "Failed to get app information")
        }
      }
    } catch (e: Exception) {
      promise.reject("APP_INFO_ERROR", e.message, e)
    }
  }

  private fun parseLanguage(value: String): Language =
    Language.values().firstOrNull { it.name.equals(value, ignoreCase = true) } ?: Language.EN
}
