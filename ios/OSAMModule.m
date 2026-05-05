#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(OSAMModule, NSObject)

RCT_EXTERN_METHOD(versionControl:(NSString *)languageCode
                  isDarkMode:(BOOL)isDarkMode
                  applyComModStyles:(BOOL)applyComModStyles
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rating:(NSString *)languageCode
                  isDarkMode:(BOOL)isDarkMode
                  applyComModStyles:(BOOL)applyComModStyles
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(deviceInformation:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(appInformation:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(changeLanguageEvent:(NSString *)languageCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(firstTimeOrUpdateEvent:(NSString *)languageCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(subscribeToCustomTopic:(NSString *)topic
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(unsubscribeToCustomTopic:(NSString *)topic
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getFCMToken:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isOnline:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
