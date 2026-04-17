package cat.bcn.osam.reactnative

/**
 * Static configuration read by [OSAMPackage] when autolinking instantiates it
 * via the no-arg constructor. Set [wrappersFactory] in `Application.onCreate`
 * BEFORE the React Native bridge starts (i.e. before `SoLoader.init`).
 *
 * Mirrors the iOS `OSAMConfiguration.wrappersProvider` pattern so the two
 * platforms behave consistently.
 *
 * If not set, [DefaultOSAMWrappersFactory] (Firebase-backed) is used.
 */
object OSAMConfiguration {
  var wrappersFactory: OSAMWrappersFactory = DefaultOSAMWrappersFactory()
}
