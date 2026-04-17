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
  func checkVersionControl(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.versionControl(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name, "description": response.debugDescription])
    }
  }

  @objc
  func showRatingDialog(
    _ languageCode: String,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    osamCommons.rating(language: parseLanguage(languageCode)) { response in
      resolver(["status": response.name, "description": response.debugDescription])
    }
  }

  @objc
  func getDeviceInformation(
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
  func getAppInformation(
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

  private func parseLanguage(_ code: String) -> Language {
    switch code.lowercased() {
    case "ca": return .ca
    case "es": return .es
    case "en": return .en
    default: return .en
    }
  }
}
