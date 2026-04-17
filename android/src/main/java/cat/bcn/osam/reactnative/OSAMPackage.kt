package cat.bcn.osam.reactnative

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

/**
 * React Native package for `react-native-modul-comu-osam`.
 *
 * Autolinking instantiates this via the no-arg constructor, which reads the
 * wrappers factory from [OSAMConfiguration.wrappersFactory]. To swap out the
 * Firebase defaults, set [OSAMConfiguration.wrappersFactory] in
 * `Application.onCreate` before the RN bridge starts.
 *
 * The explicit-factory constructor is kept for callers that opt out of
 * autolinking and register the package manually.
 */
class OSAMPackage : ReactPackage {

  private val wrappersFactory: OSAMWrappersFactory

  constructor() {
    this.wrappersFactory = OSAMConfiguration.wrappersFactory
  }

  constructor(wrappersFactory: OSAMWrappersFactory) {
    this.wrappersFactory = wrappersFactory
  }

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> =
    listOf(OSAMModule(reactContext, wrappersFactory))

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> =
    emptyList()
}
