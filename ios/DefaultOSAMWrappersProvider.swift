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
  private let debug: Bool

  @objc public override convenience init() {
    self.init(backendEndpoint: nil, debug: false)
  }

  @objc public convenience init(backendEndpoint: String?) {
    self.init(backendEndpoint: backendEndpoint, debug: false)
  }

  /// - Parameter debug: when `true`, internal failure paths in the default
  ///   wrappers send breadcrumbs to Crashlytics via `Crashlytics.log(...)`.
  ///   Defaults to `false` so production apps stay silent.
  @objc public init(backendEndpoint: String?, debug: Bool) {
    self.explicitEndpoint = backendEndpoint
    self.debug = debug
    super.init()
  }

  public var backendEndpoint: String {
    if let explicit = explicitEndpoint { return explicit }
    guard
      let path = Bundle.main.path(forResource: "config_keys", ofType: "plist"),
      let dict = NSDictionary(contentsOfFile: path),
      let endpoint = dict["common_module_endpoint"] as? String,
      !endpoint.isEmpty
    else {
      // Returning empty signals "not configured" to OSAMModule, which then
      // resolves OSAM calls with a graceful ERROR instead of crashing the
      // app. fatalError here would defeat the whole graceful-init contract.
      let issue = "DefaultOSAMWrappersProvider.backendEndpoint: common_module_endpoint missing from config_keys.plist. " +
        "Either add it, or pass an explicit backendEndpoint to DefaultOSAMWrappersProvider."
      if debug {
        Crashlytics.crashlytics().log(issue)
        Crashlytics.crashlytics().record(error: NSError(
          domain: "OSAMReactNativeDebug",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: issue]
        ))
      }
      return ""
    }
    return endpoint
  }

  public func makeCrashlyticsWrapper() -> CrashlyticsWrapper { FirebaseCrashlyticsWrapper() }
  public func makePerformanceWrapper() -> PerformanceWrapper { FirebasePerformanceWrapper(debug: debug) }
  public func makeAnalyticsWrapper() -> AnalyticsWrapper { FirebaseAnalyticsWrapper() }
  public func makePlatformUtil() -> PlatformUtil { DefaultPlatformUtil(debug: debug) }
  public func makeMessagingWrapper() -> MessagingWrapper { FirebaseMessagingWrapper(debug: debug) }
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
  private let debug: Bool

  init(debug: Bool) {
    self.debug = debug
  }

  private func logFailure(_ reason: String, url: String, httpMethod: String) {
    guard debug else { return }
    let issue = "FirebasePerformanceWrapper.createMetric: \(reason) — url=\(redactUrl(url)), httpMethod=\(httpMethod)"
    Crashlytics.crashlytics().log(issue)
    Crashlytics.crashlytics().record(error: NSError(
      domain: "OSAMReactNativeDebug",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: issue]
    ))
  }

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
    guard !url.isEmpty else {
      logFailure("empty URL string", url: url, httpMethod: httpMethod)
      return nil
    }
    guard let urlObj = URL(string: url) else {
      logFailure("invalid URL string", url: url, httpMethod: httpMethod)
      return nil
    }
    guard let scheme = urlObj.scheme, scheme == "http" || scheme == "https" else {
      logFailure("unsupported URL scheme", url: url, httpMethod: httpMethod)
      return nil
    }
    // HTTPMetric crashes if host is empty (e.g. "http:///path").
    guard let host = urlObj.host, !host.isEmpty else {
      logFailure("empty URL host", url: url, httpMethod: httpMethod)
      return nil
    }
    guard let metric = HTTPMetric(url: urlObj, httpMethod: method) else {
      logFailure("HTTPMetric init returned nil", url: url, httpMethod: httpMethod)
      return nil
    }
    return FirebasePerformanceMetric(metric: metric)
  }
}

// Truncates `s` to fit within `maxBytes` UTF-8 bytes, never splitting a
// Unicode scalar (so the result is always valid UTF-8 / valid Swift String).
internal func truncateUtf8(_ s: String, maxBytes: Int) -> String {
  if s.isEmpty || maxBytes <= 0 { return "" }
  var bytes = 0
  var result = ""
  for scalar in s.unicodeScalars {
    let scalarBytes = scalar.utf8.count
    if bytes + scalarBytes > maxBytes { break }
    result.unicodeScalars.append(scalar)
    bytes += scalarBytes
  }
  return result
}

// URL query/fragment may carry tokens or PII. Strip down to scheme://host/path
// before logging anywhere off-device (Crashlytics breadcrumbs).
internal func redactUrl(_ url: String) -> String {
  if url.isEmpty { return "<empty>" }
  guard
    let u = URL(string: url),
    let scheme = u.scheme, !scheme.isEmpty,
    let host = u.host, !host.isEmpty
  else {
    return "<malformed>"
  }
  return "\(scheme)://\(host)\(u.path)"
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
  func putAttribute(attribute: String, value: String) {
    guard !attribute.isEmpty else { return }
    // Firebase only accepts ASCII [A-Za-z0-9_], must start with a letter,
    // key ≤ 40 chars, value ≤ 100 chars. Out-of-spec attrs are silently dropped
    // by Firebase, so sanitize here to keep them observable.
    // CharacterSet.alphanumerics matches all Unicode letters/digits, which
    // is too permissive — use an explicit ASCII set instead.
    let asciiAllowed = CharacterSet(charactersIn:
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_")
    let asciiLetters = CharacterSet(charactersIn:
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    var sanitized = attribute
      .components(separatedBy: asciiAllowed.inverted)
      .joined(separator: "_")
    if let first = sanitized.unicodeScalars.first, !asciiLetters.contains(first) {
      sanitized = "a_" + sanitized
    }
    // Key is ASCII after sanitize → byte count == char count, prefix(40) safe.
    // Value can hold any Unicode; Firebase enforces 100 server-side per UTF-8
    // byte. Truncate by UTF-8 bytes, never splitting a Unicode scalar.
    let truncatedKey = String(sanitized.prefix(40))
    let truncatedValue = truncateUtf8(value, maxBytes: 100)
    metric?.setValue(truncatedValue, forAttribute: truncatedKey)
  }
  func stop() { metric?.stop() }
}

class DefaultPlatformUtil: PlatformUtil {
  private let debug: Bool

  init(debug: Bool) {
    self.debug = debug
  }

  func encodeUrl(url: String) -> String? {
    url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
  }

  func openUrl(url: String) -> Bool {
    guard let urlObj = URL(string: url) else {
      if debug {
        let issue = "DefaultPlatformUtil.openUrl: invalid URL string — url=\(redactUrl(url))"
        Crashlytics.crashlytics().log(issue)
        Crashlytics.crashlytics().record(error: NSError(
          domain: "OSAMReactNativeDebug",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: issue]
        ))
      }
      return false
    }
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
  private let debug: Bool

  init(debug: Bool) {
    self.debug = debug
  }

  func getToken() async throws -> String {
    do {
      return try await Messaging.messaging().token()
    } catch {
      if debug {
        let issue = "FirebaseMessagingWrapper.getToken: \(error.localizedDescription)"
        Crashlytics.crashlytics().log(issue)
        Crashlytics.crashlytics().record(error: error as NSError)
      }
      throw error
    }
  }

  func subscribeToTopic(topic: String) async throws {
    do {
      try await Messaging.messaging().subscribe(toTopic: topic)
    } catch {
      if debug {
        let issue = "FirebaseMessagingWrapper.subscribeToTopic: topic=\(topic), error=\(error.localizedDescription)"
        Crashlytics.crashlytics().log(issue)
        Crashlytics.crashlytics().record(error: error as NSError)
      }
      throw error
    }
  }

  func unsubscribeFromTopic(topic: String) async throws {
    do {
      try await Messaging.messaging().unsubscribe(fromTopic: topic)
    } catch {
      if debug {
        let issue = "FirebaseMessagingWrapper.unsubscribeFromTopic: topic=\(topic), error=\(error.localizedDescription)"
        Crashlytics.crashlytics().log(issue)
        Crashlytics.crashlytics().record(error: error as NSError)
      }
      throw error
    }
  }
}
