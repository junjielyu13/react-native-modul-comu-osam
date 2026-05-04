//
//  OSAMModule.swift
//  react-native-modul-comu-osam
//

import Foundation
import React
import UIKit
import OSAMCommon

@objc(OSAMModule)
public class OSAMModule: NSObject, RCTBridgeModule {

  public static func moduleName() -> String! { "OSAMModule" }
  public static func requiresMainQueueSetup() -> Bool { true }

  // Cached OSAMCommons + the rootVC it was constructed against. Read/written
  // on main only. We track the rootVC because `OSAMCommons` (Kotlin/Native)
  // doesn't expose `setVc(...)` on iOS, so a changed rootVC means we must
  // re-construct rather than dispatch on a stale view controller.
  private var _osamCommons: OSAMCommons?
  private weak var _osamCommonsRootVC: UIViewController?

  // Picks the most-foreground UIWindowScene (helps on iPad multi-window)
  // and falls back gracefully when no key window is set yet.
  private func resolveRootViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first(where: { $0.activationState == .foregroundActive })
      ?? scenes.first(where: { $0.activationState == .foregroundInactive })
      ?? scenes.first
    guard let scene = scene else { return nil }
    let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    return keyWindow?.rootViewController
  }

  // Resolves OSAMCommons, retrying briefly while rootViewController is missing
  // (cold-start race). Calls completion on main with nil if it never appears
  // or if the configured backendEndpoint is empty (provider not configured).
  private func resolveOsamCommons(completion: @escaping (OSAMCommons?) -> Void) {
    attemptResolveOsamCommons(retriesLeft: 10, completion: completion) // ~1s upper bound
  }

  private func attemptResolveOsamCommons(
    retriesLeft: Int,
    completion: @escaping (OSAMCommons?) -> Void
  ) {
    guard let rootVC = resolveRootViewController() else {
      if retriesLeft <= 0 { completion(nil); return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        guard let self = self else { completion(nil); return }
        self.attemptResolveOsamCommons(retriesLeft: retriesLeft - 1, completion: completion)
      }
      return
    }
    // Cache hit only when the live rootVC matches the one we built against.
    // If the host swapped its rootVC (multi-window iPad, programmatic root
    // replacement) the weak reference may be nil or pointing elsewhere —
    // either way we re-construct.
    if let existing = _osamCommons, _osamCommonsRootVC === rootVC {
      completion(existing)
      return
    }
    let provider = OSAMConfiguration.wrappersProvider
    let endpoint = provider.backendEndpoint
    guard !endpoint.isEmpty else {
      // backendEndpoint missing — provider not configured. Treat as init
      // failure rather than constructing OSAMCommons against an empty URL.
      completion(nil)
      return
    }
    let instance = OSAMCommons(
      vc: rootVC,
      backendEndpoint: endpoint,
      crashlyticsWrapper: provider.makeCrashlyticsWrapper(),
      performanceWrapper: provider.makePerformanceWrapper(),
      analyticsWrapper: provider.makeAnalyticsWrapper(),
      platformUtil: provider.makePlatformUtil(),
      messagingWrapper: provider.makeMessagingWrapper()
    )
    _osamCommons = instance
    _osamCommonsRootVC = rootVC
    completion(instance)
  }

  // For methods that contract on OSAMStatusResponse — init failure resolves
  // with `{ status: "ERROR", description: ... }` so callers don't have to
  // catch promise rejections separately from real ERROR results.
  private func withCommonsStatus(
    resolver: @escaping RCTPromiseResolveBlock,
    _ block: @escaping (OSAMCommons) -> Void
  ) {
    DispatchQueue.main.async {
      self.resolveOsamCommons { commons in
        guard let commons = commons else {
          resolver([
            "status": "ERROR",
            "description": "OSAMCommons could not be initialized: rootViewController unavailable or backendEndpoint not configured",
          ])
          return
        }
        block(commons)
      }
    }
  }

  // For methods that resolve with a data object (deviceInformation /
  // appInformation / getFCMToken) — init failure rejects, matching the
  // existing failure semantics of those methods.
  private func withCommons(
    rejecter: @escaping RCTPromiseRejectBlock,
    _ block: @escaping (OSAMCommons) -> Void
  ) {
    DispatchQueue.main.async {
      self.resolveOsamCommons { commons in
        guard let commons = commons else {
          rejecter(
            "INIT_ERROR",
            "OSAMCommons could not be initialized: rootViewController unavailable or backendEndpoint not configured",
            nil
          )
          return
        }
        block(commons)
      }
    }
  }

  @objc
  func versionControl(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.versionControl(language: self.parseLanguage(languageCode)) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func rating(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.rating(language: self.parseLanguage(languageCode)) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func deviceInformation(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommons(rejecter: rejecter) { commons in
      commons.deviceInformation { response, info in
        if response.name == "ACCEPTED", let info = info {
          resolver([
            "platformName": info.platformName,
            "platformVersion": info.platformVersion,
            "platformModel": info.platformModel,
          ])
        } else {
          rejecter("DEVICE_INFO_ERROR", "Failed to get device information", nil)
        }
      }
    }
  }

  @objc
  func appInformation(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommons(rejecter: rejecter) { commons in
      commons.appInformation { response, info in
        if response.name == "ACCEPTED", let info = info {
          resolver([
            "appName": info.appName,
            "appVersionName": info.appVersionName,
            "appVersionCode": info.appVersionCode,
          ])
        } else {
          rejecter("APP_INFO_ERROR", "Failed to get app information", nil)
        }
      }
    }
  }

  @objc
  func changeLanguageEvent(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.changeLanguageEvent(language: self.parseLanguage(languageCode)) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func firstTimeOrUpdateEvent(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.firstTimeOrUpdateEvent(language: self.parseLanguage(languageCode)) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func subscribeToCustomTopic(
    _ topic: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.subscribeToCustomTopic(topic: topic) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func unsubscribeToCustomTopic(
    _ topic: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommonsStatus(resolver: resolver) { commons in
      commons.unsubscribeToCustomTopic(topic: topic) { response in
        resolver(["status": response.name])
      }
    }
  }

  @objc
  func getFCMToken(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    withCommons(rejecter: rejecter) { commons in
      commons.getFCMToken { response in
        if let success = response as? TokenResponse.Success {
          resolver(["token": success.token])
        } else if let errorResp = response as? TokenResponse.Error {
          rejecter("FCM_TOKEN_ERROR", errorResp.error.message ?? "Failed to get FCM token", nil)
        } else {
          rejecter("FCM_TOKEN_ERROR", "Unknown TokenResponse", nil)
        }
      }
    }
  }

  private func parseLanguage(_ code: String) -> Language {
    switch code.lowercased() {
    case "ca": return .ca
    case "es": return .es
    case "en": return .en
    default: return .en
    }
  }
}
