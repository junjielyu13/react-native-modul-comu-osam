//
//  NoopWrappersProvider.swift
//  Example
//
//  No-op provider used by the example app to avoid requiring Firebase
//  configuration. Demonstrates the Option 3 override path.
//

import Foundation
import OSAMCommon
import react_native_modul_comu_osam

class NoopWrappersProvider: NSObject, OSAMWrappersProvider {
  var backendEndpoint: String { "https://dev-osam-modul-comu.dtibcn.cat/" }
  func makeCrashlyticsWrapper() -> CrashlyticsWrapper { NoopCrashlytics() }
  func makePerformanceWrapper() -> PerformanceWrapper { NoopPerformance() }
  func makeAnalyticsWrapper() -> AnalyticsWrapper { NoopAnalytics() }
  func makePlatformUtil() -> PlatformUtil { NoopPlatformUtil() }
  func makeMessagingWrapper() -> MessagingWrapper { NoopMessaging() }
}

private class NoopCrashlytics: CrashlyticsWrapper {
  func recordException(className: String, stackTrace: String) {
    NSLog("OSAM-Noop recordException: \(className) — \(stackTrace)")
  }
}

private class NoopAnalytics: AnalyticsWrapper {
  func logEvent(name: String, parameters: [String: String]) {
    NSLog("OSAM-Noop logEvent: \(name) \(parameters)")
  }
}

private class NoopPerformance: PerformanceWrapper {
  func createMetric(url: String, httpMethod: String) -> PerformanceMetric? {
    NoopMetric()
  }
}

private class NoopMetric: PerformanceMetric {
  func start() {}
  func setRequestPayloadSize(bytes: Int64) {}
  func markRequestComplete() {}
  func markResponseStart() {}
  func setResponseContentType(contentType: String) {}
  func setHttpResponseCode(responseCode: Int32) {}
  func setResponsePayloadSize(bytes: Int64) {}
  func putAttribute(attribute: String, value: String) {}
  func stop() {}
}

private class NoopPlatformUtil: PlatformUtil {
  func encodeUrl(url: String) -> String? { url }
  func openUrl(url: String) -> Bool { false }
  func getDeviceModelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    return mirror.children.reduce("") { id, element in
      guard let value = element.value as? Int8, value != 0 else { return id }
      return id + String(UnicodeScalar(UInt8(value)))
    }
  }
}

private class NoopMessaging: MessagingWrapper {
  func getToken() async throws -> String { "noop-token" }
  func subscribeToTopic(topic: String) async throws {}
  func unsubscribeFromTopic(topic: String) async throws {}
}
