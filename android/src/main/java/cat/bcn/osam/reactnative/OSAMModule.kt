package cat.bcn.osam.reactnative

import cat.bcn.commonmodule.ui.versioncontrol.Language
import cat.bcn.commonmodule.ui.versioncontrol.OSAMCommons
import cat.bcn.commonmodule.ui.versioncontrol.TokenResponse
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

  private fun refreshActivity() {
    currentActivity?.let { osamCommons.setActivity(it) }
  }

  @ReactMethod
  fun versionControl(languageCode: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.versionControl(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("VERSION_CONTROL_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun rating(languageCode: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.rating(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("RATING_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun deviceInformation(promise: Promise) {
    try {
      refreshActivity()
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
  fun appInformation(promise: Promise) {
    try {
      refreshActivity()
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

  @ReactMethod
  fun changeLanguageEvent(languageCode: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.changeLanguageEvent(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("CHANGE_LANGUAGE_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun firstTimeOrUpdateEvent(languageCode: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.firstTimeOrUpdateEvent(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("FIRST_TIME_OR_UPDATE_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun subscribeToCustomTopic(topic: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.subscribeToCustomTopic(topic) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("SUBSCRIBE_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun unsubscribeToCustomTopic(topic: String, promise: Promise) {
    try {
      refreshActivity()
      osamCommons.unsubscribeToCustomTopic(topic) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    } catch (e: Exception) {
      promise.reject("UNSUBSCRIBE_ERROR", e.message, e)
    }
  }

  @ReactMethod
  fun getFCMToken(promise: Promise) {
    try {
      refreshActivity()
      osamCommons.getFCMToken { response ->
        when (response) {
          is TokenResponse.Success ->
            promise.resolve(WritableNativeMap().apply { putString("token", response.token) })
          is TokenResponse.Error ->
            promise.reject("FCM_TOKEN_ERROR", response.error.message ?: "Failed to get FCM token", response.error)
        }
      }
    } catch (e: Exception) {
      promise.reject("FCM_TOKEN_ERROR", e.message, e)
    }
  }

  private fun parseLanguage(value: String): Language =
    Language.values().firstOrNull { it.name.equals(value, ignoreCase = true) } ?: Language.EN
}
