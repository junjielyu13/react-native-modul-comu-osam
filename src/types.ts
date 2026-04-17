export enum OSAMResultEnum {
  CANCELLED = 'CANCELLED',
  DISMISS = 'DISMISS',
  ACCEPTED = 'ACCEPTED',
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

export interface OSAMModuleInterface {
  checkVersionControl(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;
  showRatingDialog(languageCode: OSAMLanguage | string): Promise<OSAMStatusResponse>;
  getDeviceInformation(): Promise<OSAMDeviceInformation>;
  getAppInformation(): Promise<OSAMAppInformation>;
}
