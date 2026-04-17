import { NativeModules, Platform } from 'react-native';
import type { OSAMModuleInterface } from './types';

const LINKING_ERROR =
  `The package 'react-native-modul-comu-osam' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go (this package requires native code)\n';

const OSAMModule = (NativeModules.OSAMModule
  ? NativeModules.OSAMModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    )) as OSAMModuleInterface;

export default OSAMModule;
export * from './types';
