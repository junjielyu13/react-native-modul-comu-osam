export enum OSAMResultEnum {
  ACCEPTED = 'ACCEPTED',
  DISMISSED = 'DISMISSED',
  CANCELLED = 'CANCELLED',
  SUCCESS = 'SUCCESS',
  UNCHANGED = 'UNCHANGED',
  ERROR = 'ERROR',
}

export type OSAMLanguage = 'ca' | 'es' | 'en';

export interface OSAMStatusResponse {
  status: `${OSAMResultEnum}` | string;
  description?: string;
}

export interface OSAMDeviceInformation {
  platformName: string;
  platformVersion: string;
  platformModel: string;
}

export interface OSAMAppInformation {
  appName: string;
  appVersionName: string;
  appVersionCode: string;
}

export interface OSAMFCMTokenResponse {
  token: string;
}

export interface OSAMModuleInterface {
  /** Force / recommended / info update dialog. Resolves with ACCEPTED | DISMISSED | CANCELLED | ERROR. */
  versionControl(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;

  /** Native rating dialog. Resolves with ACCEPTED | DISMISSED | ERROR. */
  rating(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;

  /** Returns platform name / version / model. */
  deviceInformation(): Promise<OSAMDeviceInformation>;

  /** Returns app name / version name / version code. */
  appInformation(): Promise<OSAMAppInformation>;

  /** Updates preferences, logs analytics, and rotates FCM topic subscriptions for the new language.
   *  Resolves with SUCCESS | UNCHANGED | ERROR. */
  changeLanguageEvent(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;

  /** Initial subscription or FCM topic updates on app startup / update.
   *  Resolves with SUCCESS | UNCHANGED | ERROR. */
  firstTimeOrUpdateEvent(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;

  /** Subscribes the device to a custom Firebase topic. Resolves with ACCEPTED | ERROR. */
  subscribeToCustomTopic(topic: string): Promise<OSAMStatusResponse>;

  /** Unsubscribes the device from a custom Firebase topic. Resolves with ACCEPTED | ERROR. */
  unsubscribeToCustomTopic(topic: string): Promise<OSAMStatusResponse>;

  /** Returns the FCM registration token. Rejects if retrieval fails. */
  getFCMToken(): Promise<OSAMFCMTokenResponse>;
}
