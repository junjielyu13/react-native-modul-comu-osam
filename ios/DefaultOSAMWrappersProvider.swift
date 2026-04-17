//
//  DefaultOSAMWrappersProvider.swift
//  react-native-modul-comu-osam
//

import Foundation
import UIKit
import OSAMCommon
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance
import FirebaseMessaging

/// Default provider backed by Firebase.
///
/// Resolves `backendEndpoint` from the main bundle's `config_keys.plist`
/// (key: `common_module_endpoint`) unless an explicit value is passed.
@objc public class DefaultOSAMWrappersProvider: NSObject, OSAMWrappersProvider {
  private let explicitEndpoint: String?

  @objc public override convenience init() {
    self.init(backendEndpoint: nil)
  }

  @objc public init(backendEndpoint: String?) {
    self.explicitEndpoint = backendEndpoint
    super.init()
  }

  public var backendEndpoint: String {
    if let explicit = explicitEndpoint { return explicit }
    guard
      let path = Bundle.main.path(forResource: "config_keys", ofType: "plist"),
      let dict = NSDictionary(contentsOfFile: path),
      let endpoint = dict["common_module_endpoint"] as? String
    else {
      fatalError(
        "common_module_endpoint not found in config_keys.plist. " +
        "Either add it, or pass an explicit backendEndpoint to DefaultOSAMWrappersProvider."
      )
    }
    return endpoint
  }

  public func makeCrashlyticsWrapper() -> CrashlyticsWrapper { FirebaseCrashlyticsWrapper() }
  public func makePerformanceWrapper() -> PerformanceWrapper { FirebasePerformanceWrapper() }
  public func makeAnalyticsWrapper() -> AnalyticsWrapper { FirebaseAnalyticsWrapper() }
  public func makePlatformUtil() -> PlatformUtil { DefaultPlatformUtil() }
  public func makeMessagingWrapper() -> MessagingWrapper { FirebaseMessagingWrapper() }
}

// MARK: - Firebase wrapper implementations

class FirebaseCrashlyticsWrapper: CrashlyticsWrapper {
  func recordException(className: String, stackTrace: String) {
    let exception = ExceptionModel(name: className, reason: stackTrace)
    Crashlytics.crashlytics().record(exceptionModel: exception)
  }
}

class FirebaseAnalyticsWrapper: AnalyticsWrapper {
  func logEvent(name: String, parameters: [String: String]) {
    Analytics.logEvent(name, parameters: parameters)
  }
}

class FirebasePerformanceWrapper: PerformanceWrapper {
  func createMetric(url: String, httpMethod: String) -> PerformanceMetric? {
    let method: HTTPMethod
    switch httpMethod.lowercased() {
    case "put": method = .put
    case "post": method = .post
    case "delete": method = .delete
    case "head": method = .head
    case "patch": method = .patch
    case "options": method = .options
    case "trace": method = .trace
    case "connect": method = .connect
    default: method = .get
    }
    guard let url = URL(string: url), let metric = HTTPMetric(url: url, httpMethod: method) else {
      return nil
    }
    return FirebasePerformanceMetric(metric: metric)
  }
}

class FirebasePerformanceMetric: PerformanceMetric {
  private let metric: HTTPMetric?

  init(metric: HTTPMetric?) {
    self.metric = metric
  }

  func start() { metric?.start() }
  func setRequestPayloadSize(bytes: Int64) { metric?.requestPayloadSize = Int(bytes) }
  func markRequestComplete() {}
  func markResponseStart() {}
  func setResponseContentType(contentType: String) { metric?.responseContentType = contentType }
  func setHttpResponseCode(responseCode: Int32) { metric?.responseCode = Int(responseCode) }
  func setResponsePayloadSize(bytes: Int64) { metric?.responsePayloadSize = Int(bytes) }
  func putAttribute(attribute: String, value: String) { metric?.setValue(value, forAttribute: attribute) }
  func stop() { metric?.stop() }
}

class DefaultPlatformUtil: PlatformUtil {
  func encodeUrl(url: String) -> String? {
    url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
  }

  func openUrl(url: String) -> Bool {
    guard let urlObj = URL(string: url) else { return false }
    DispatchQueue.main.async { UIApplication.shared.open(urlObj) }
    return true
  }

  func getDeviceModelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    return machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
  }
}

class FirebaseMessagingWrapper: MessagingWrapper {
  func getToken() async throws -> String {
    try await Messaging.messaging().token()
  }
  func subscribeToTopic(topic: String) async throws {
    try await Messaging.messaging().subscribe(toTopic: topic)
  }
  func unsubscribeFromTopic(topic: String) async throws {
    try await Messaging.messaging().unsubscribe(fromTopic: topic)
  }
}
