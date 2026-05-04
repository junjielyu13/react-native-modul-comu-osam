import { NativeModules, Platform } from 'react-native';
import type {
  OSAMAppInformation,
  OSAMDeviceInformation,
  OSAMFCMTokenResponse,
  OSAMModuleInterface,
  OSAMOnlineResponse,
  OSAMStatusResponse,
} from './types';

const LINKING_ERROR =
  `The package 'react-native-modul-comu-osam' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go (this package requires native code)\n';

// Native bridge — same arity as the upstream OSAM 3.2.0 Kotlin / Swift API:
// `versionControl(language, isDarkMode, applyComModStyles, callback)`. The JS
// layer below substitutes the upstream defaults (`false` / `true`) when the
// caller omits them so the bridge call is always shaped the same way.
type OSAMNativeModule = {
  versionControl(
    languageCode: string,
    isDarkMode: boolean,
    applyComModStyles: boolean
  ): Promise<OSAMStatusResponse>;
  rating(
    languageCode: string,
    isDarkMode: boolean,
    applyComModStyles: boolean
  ): Promise<OSAMStatusResponse>;
  deviceInformation(): Promise<OSAMDeviceInformation>;
  appInformation(): Promise<OSAMAppInformation>;
  changeLanguageEvent(languageCode: string): Promise<OSAMStatusResponse>;
  firstTimeOrUpdateEvent(languageCode: string): Promise<OSAMStatusResponse>;
  subscribeToCustomTopic(topic: string): Promise<OSAMStatusResponse>;
  unsubscribeToCustomTopic(topic: string): Promise<OSAMStatusResponse>;
  getFCMToken(): Promise<OSAMFCMTokenResponse>;
  isOnline(): Promise<OSAMOnlineResponse>;
};

const Native: OSAMNativeModule = (NativeModules.OSAMModule
  ? NativeModules.OSAMModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    )) as OSAMNativeModule;

const OSAMModule: OSAMModuleInterface = {
  versionControl: (languageCode, isDarkMode = false, applyComModStyles = true) =>
    Native.versionControl(languageCode, isDarkMode, applyComModStyles),
  rating: (languageCode, isDarkMode = false, applyComModStyles = true) =>
    Native.rating(languageCode, isDarkMode, applyComModStyles),
  deviceInformation: () => Native.deviceInformation(),
  appInformation: () => Native.appInformation(),
  changeLanguageEvent: (languageCode) => Native.changeLanguageEvent(languageCode),
  firstTimeOrUpdateEvent: (languageCode) => Native.firstTimeOrUpdateEvent(languageCode),
  subscribeToCustomTopic: (topic) => Native.subscribeToCustomTopic(topic),
  unsubscribeToCustomTopic: (topic) => Native.unsubscribeToCustomTopic(topic),
  getFCMToken: () => Native.getFCMToken(),
  isOnline: () => Native.isOnline(),
};

export default OSAMModule;
export * from './types';
