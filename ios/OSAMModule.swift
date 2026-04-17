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

  private lazy var osamCommons: OSAMCommons = {
    guard let rootVC = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController
    else {
      fatalError("OSAMCommons initialization failed: no key window rootViewController.")
    }

    let provider = OSAMConfiguration.wrappersProvider
    return OSAMCommons(
      vc: rootVC,
      backendEndpoint: provider.backendEndpoint,
      crashlyticsWrapper: provider.makeCrashlyticsWrapper(),
      performanceWrapper: provider.makePerformanceWrapper(),
      analyticsWrapper: provider.makeAnalyticsWrapper(),
      platformUtil: provider.makePlatformUtil(),
      messagingWrapper: provider.makeMessagingWrapper()
    )
  }()

  @objc
  func versionControl(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.versionControl(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func rating(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.rating(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func deviceInformation(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.deviceInformation { response, info in
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

  @objc
  func appInformation(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.appInformation { response, info in
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

  @objc
  func changeLanguageEvent(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.changeLanguageEvent(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func firstTimeOrUpdateEvent(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.firstTimeOrUpdateEvent(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func subscribeToCustomTopic(
    _ topic: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.subscribeToCustomTopic(topic: topic) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func unsubscribeToCustomTopic(
    _ topic: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.unsubscribeToCustomTopic(topic: topic) { response in
      resolver(["status": response.name])
    }
  }

  @objc
  func getFCMToken(
    _ resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.getFCMToken { response in
      if let success = response as? TokenResponse.Success {
        resolver(["token": success.token])
      } else if let errorResp = response as? TokenResponse.Error {
        rejecter("FCM_TOKEN_ERROR", errorResp.error.message ?? "Failed to get FCM token", nil)
      } else {
        rejecter("FCM_TOKEN_ERROR", "Unknown TokenResponse", nil)
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
