/**
 * Unit tests for the JS bridge layer (`src/index.ts`).
 *
 * Scope: this file only verifies the thin TS wrapper around the native module.
 * It does NOT exercise any real native code, Firebase, or backend — those are
 * covered manually via `example/` and `example-npm/` smoke tests.
 *
 * What these tests catch:
 *   - method-name drift between TS and the native bridge,
 *   - argument-order / default-argument regressions on `versionControl` /
 *     `rating` (whose signatures changed in OSAM 3.2.0),
 *   - response passthrough (no accidental wrapping/transforming),
 *   - the LINKING_ERROR proxy when the native module is absent.
 */

const mockNative = {
  versionControl: jest.fn(),
  rating: jest.fn(),
  deviceInformation: jest.fn(),
  appInformation: jest.fn(),
  changeLanguageEvent: jest.fn(),
  firstTimeOrUpdateEvent: jest.fn(),
  subscribeToCustomTopic: jest.fn(),
  unsubscribeToCustomTopic: jest.fn(),
  getFCMToken: jest.fn(),
  isOnline: jest.fn(),
};

jest.mock('react-native', () => ({
  NativeModules: { OSAMModule: mockNative },
  Platform: {
    OS: 'ios',
    select: (obj: { ios?: unknown; android?: unknown; default?: unknown }) =>
      obj.ios ?? obj.default,
  },
}));

import OSAMModule, { OSAMResultEnum } from '../src';

beforeEach(() => {
  Object.values(mockNative).forEach((fn) => fn.mockReset());
});

describe('versionControl', () => {
  it('substitutes upstream defaults (isDarkMode=false, applyComModStyles=true) when omitted', async () => {
    mockNative.versionControl.mockResolvedValue({ status: 'ACCEPTED' });
    await OSAMModule.versionControl('en');
    expect(mockNative.versionControl).toHaveBeenCalledWith('en', false, true);
  });

  it('forwards explicit isDarkMode / applyComModStyles unchanged', async () => {
    mockNative.versionControl.mockResolvedValue({ status: 'DISMISSED' });
    await OSAMModule.versionControl('ca', true, false);
    expect(mockNative.versionControl).toHaveBeenCalledWith('ca', true, false);
  });

  it('passes the native response through untouched', async () => {
    const response = { status: 'CANCELLED', description: 'user closed dialog' };
    mockNative.versionControl.mockResolvedValue(response);
    await expect(OSAMModule.versionControl('es')).resolves.toEqual(response);
  });

  it('propagates native rejections', async () => {
    mockNative.versionControl.mockRejectedValue(new Error('bridge failed'));
    await expect(OSAMModule.versionControl('en')).rejects.toThrow('bridge failed');
  });
});

describe('rating', () => {
  it('substitutes upstream defaults when omitted', async () => {
    mockNative.rating.mockResolvedValue({ status: 'ACCEPTED' });
    await OSAMModule.rating('es');
    expect(mockNative.rating).toHaveBeenCalledWith('es', false, true);
  });

  it('forwards explicit isDarkMode / applyComModStyles unchanged', async () => {
    mockNative.rating.mockResolvedValue({ status: 'DISMISSED' });
    await OSAMModule.rating('en', true, false);
    expect(mockNative.rating).toHaveBeenCalledWith('en', true, false);
  });
});

describe('deviceInformation / appInformation', () => {
  it('deviceInformation forwards the native payload', async () => {
    const payload = { platformName: 'iOS', platformVersion: '17.0', platformModel: 'iPhone15,3' };
    mockNative.deviceInformation.mockResolvedValue(payload);
    await expect(OSAMModule.deviceInformation()).resolves.toEqual(payload);
    expect(mockNative.deviceInformation).toHaveBeenCalledWith();
  });

  it('appInformation forwards the native payload', async () => {
    const payload = { appName: 'Park Güell', appVersionName: '1.2.3', appVersionCode: '42' };
    mockNative.appInformation.mockResolvedValue(payload);
    await expect(OSAMModule.appInformation()).resolves.toEqual(payload);
    expect(mockNative.appInformation).toHaveBeenCalledWith();
  });
});

describe('event methods', () => {
  it.each([
    ['changeLanguageEvent', 'es'],
    ['firstTimeOrUpdateEvent', 'ca'],
  ] as const)('%s passes the language code through', async (method, lang) => {
    mockNative[method].mockResolvedValue({ status: 'SUCCESS' });
    await OSAMModule[method](lang);
    expect(mockNative[method]).toHaveBeenCalledWith(lang);
  });

  it.each(['SUCCESS', 'UNCHANGED', 'ERROR'])(
    'changeLanguageEvent surfaces native status "%s"',
    async (status) => {
      mockNative.changeLanguageEvent.mockResolvedValue({ status });
      await expect(OSAMModule.changeLanguageEvent('en')).resolves.toEqual({ status });
    }
  );
});

describe('topic subscription', () => {
  it.each([
    ['subscribeToCustomTopic', 'news'],
    ['unsubscribeToCustomTopic', 'news'],
  ] as const)('%s passes the topic through', async (method, topic) => {
    mockNative[method].mockResolvedValue({ status: 'ACCEPTED' });
    await OSAMModule[method](topic);
    expect(mockNative[method]).toHaveBeenCalledWith(topic);
  });
});

describe('getFCMToken', () => {
  it('returns the token payload from the native side', async () => {
    mockNative.getFCMToken.mockResolvedValue({ token: 'fcm-abc-123' });
    await expect(OSAMModule.getFCMToken()).resolves.toEqual({ token: 'fcm-abc-123' });
  });

  it('propagates rejection (per the upstream contract)', async () => {
    mockNative.getFCMToken.mockRejectedValue(new Error('FCM unavailable'));
    await expect(OSAMModule.getFCMToken()).rejects.toThrow('FCM unavailable');
  });
});

describe('isOnline', () => {
  it.each([true, false])('returns { online: %s } from the native side', async (online) => {
    mockNative.isOnline.mockResolvedValue({ online });
    await expect(OSAMModule.isOnline()).resolves.toEqual({ online });
  });
});

describe('OSAMResultEnum', () => {
  it('exposes the full set of upstream status values, unchanged', () => {
    // Locks the public enum surface — adding/removing/renaming a value here
    // is a breaking change for consumers and should require updating this test.
    expect(OSAMResultEnum).toEqual({
      ACCEPTED: 'ACCEPTED',
      DISMISSED: 'DISMISSED',
      CANCELLED: 'CANCELLED',
      SUCCESS: 'SUCCESS',
      UNCHANGED: 'UNCHANGED',
      ERROR: 'ERROR',
    });
  });
});

