/**
 * Lives in its own file because `jest.mock('react-native', …)` is hoisted to
 * the top of the test module — meaning a single test file can only express
 * one shape of `NativeModules`. The happy-path tests in `index.test.ts` mock
 * `OSAMModule` as present; this file mocks it as absent so the LINKING_ERROR
 * proxy code path is exercised.
 */

jest.mock('react-native', () => ({
  NativeModules: {},
  Platform: {
    OS: 'ios',
    select: (obj: { ios?: unknown; default?: unknown }) =>
      obj.ios ?? obj.default,
  },
}));

import OSAMModule from '../src';

describe('LINKING_ERROR proxy', () => {
  it('throws when NativeModules.OSAMModule is missing', () => {
    expect(() => OSAMModule.deviceInformation()).toThrow(
      /doesn't seem to be linked/
    );
  });

  it('throws on every method, not just one', () => {
    // Sanity check: the Proxy `get` trap fires for any property access, so
    // every wrapper method should fail the same way.
    expect(() => OSAMModule.getFCMToken()).toThrow(/doesn't seem to be linked/);
    expect(() => OSAMModule.appInformation()).toThrow(
      /doesn't seem to be linked/
    );
  });
});
