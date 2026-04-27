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

  private var osamCommonsCache: OSAMCommons? = null

  override fun getName(): String = NAME

  // Builds OSAMCommons lazily once an Activity is available, caches it,
  // and refreshes the activity reference on subsequent calls so the
  // dialog-based methods always present from the visible Activity.
  private fun resolveOsamCommons(): OSAMCommons? {
    osamCommonsCache?.let {
      currentActivity?.let { act -> it.setActivity(act) }
      return it
    }
    val activity = currentActivity ?: return null
    val wrappers = wrappersFactory.create(reactApplicationContext)
    return OSAMCommons(
      activity = activity,
      context = reactApplicationContext,
      backendEndpoint = wrappers.backendEndpoint,
      crashlyticsWrapper = wrappers.crashlytics,
      performanceWrapper = wrappers.performance,
      analyticsWrapper = wrappers.analytics,
      platformUtil = wrappers.platformUtil,
      messagingWrapper = wrappers.messaging,
    ).also { osamCommonsCache = it }
  }

  // For methods that contract on OSAMStatusResponse — init failure or any
  // synchronous exception resolves with `{ status: "ERROR", description: ... }`
  // so callers don't have to catch promise rejections separately from real
  // ERROR results.
  private inline fun withCommonsStatus(promise: Promise, block: (OSAMCommons) -> Unit) {
    val commons = resolveOsamCommons()
    if (commons == null) {
      promise.resolve(errorStatusMap("OSAMCommons could not be initialized: no current Activity"))
      return
    }
    try {
      block(commons)
    } catch (e: Throwable) {
      promise.resolve(errorStatusMap(e.message ?: e.javaClass.simpleName))
    }
  }

  // For methods that resolve with a data object (deviceInformation /
  // appInformation / getFCMToken) — init failure rejects, matching the
  // existing failure semantics of those methods.
  private inline fun withCommons(
    promise: Promise,
    errorCode: String,
    block: (OSAMCommons) -> Unit,
  ) {
    val commons = resolveOsamCommons()
    if (commons == null) {
      promise.reject(errorCode, "OSAMCommons could not be initialized: no current Activity")
      return
    }
    try {
      block(commons)
    } catch (e: Throwable) {
      promise.reject(errorCode, e.message, e)
    }
  }

  private fun errorStatusMap(description: String): WritableNativeMap =
    WritableNativeMap().apply {
      putString("status", "ERROR")
      putString("description", description)
    }

  @ReactMethod
  fun versionControl(languageCode: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.versionControl(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun rating(languageCode: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.rating(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun deviceInformation(promise: Promise) {
    withCommons(promise, "DEVICE_INFO_ERROR") { commons ->
      commons.deviceInformation { response, info ->
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
    }
  }

  @ReactMethod
  fun appInformation(promise: Promise) {
    withCommons(promise, "APP_INFO_ERROR") { commons ->
      commons.appInformation { response, info ->
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
    }
  }

  @ReactMethod
  fun changeLanguageEvent(languageCode: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.changeLanguageEvent(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun firstTimeOrUpdateEvent(languageCode: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.firstTimeOrUpdateEvent(language = parseLanguage(languageCode)) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun subscribeToCustomTopic(topic: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.subscribeToCustomTopic(topic) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun unsubscribeToCustomTopic(topic: String, promise: Promise) {
    withCommonsStatus(promise) { commons ->
      commons.unsubscribeToCustomTopic(topic) { response ->
        promise.resolve(WritableNativeMap().apply { putString("status", response.name) })
      }
    }
  }

  @ReactMethod
  fun getFCMToken(promise: Promise) {
    withCommons(promise, "FCM_TOKEN_ERROR") { commons ->
      commons.getFCMToken { response ->
        when (response) {
          is TokenResponse.Success ->
            promise.resolve(WritableNativeMap().apply { putString("token", response.token) })
          is TokenResponse.Error ->
            promise.reject("FCM_TOKEN_ERROR", response.error.message ?: "Failed to get FCM token", response.error)
        }
      }
    }
  }

  private fun parseLanguage(value: String): Language =
    Language.values().firstOrNull { it.name.equals(value, ignoreCase = true) } ?: Language.EN
}
