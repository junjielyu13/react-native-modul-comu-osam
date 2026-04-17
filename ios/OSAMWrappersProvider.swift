//
//  OSAMWrappersProvider.swift
//  react-native-modul-comu-osam
//

import Foundation
import OSAMCommon

/// Protocol for supplying the wrappers OSAMCommons needs.
///
/// Swap the default Firebase-backed provider by assigning a custom instance
/// to `OSAMConfiguration.wrappersProvider` **before** the first call into
/// any `OSAMModule` method (typically in `AppDelegate` during launch).
@objc public protocol OSAMWrappersProvider {
  var backendEndpoint: String { get }
  func makeCrashlyticsWrapper() -> CrashlyticsWrapper
  func makePerformanceWrapper() -> PerformanceWrapper
  func makeAnalyticsWrapper() -> AnalyticsWrapper
  func makePlatformUtil() -> PlatformUtil
  func makeMessagingWrapper() -> MessagingWrapper
}

/// Static configuration surface for the RN module.
///
/// ```swift
/// // In AppDelegate.swift, before the RN bridge is created:
/// OSAMConfiguration.wrappersProvider = MyCustomWrappersProvider()
/// ```
@objc public class OSAMConfiguration: NSObject {
  @objc public static var wrappersProvider: OSAMWrappersProvider =
    DefaultOSAMWrappersProvider()

  private override init() {}
}
