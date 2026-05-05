/**
 * Minimal Jest config for the JS bridge tests.
 *
 * We deliberately do NOT use the `react-native` jest preset: `src/index.ts`
 * only touches `NativeModules` + `Platform` from `react-native`, both mocked
 * inline in the test files. Pulling in the full RN preset would require
 * Babel transforms, jsdom, and the RN test runtime — overkill for a pure-TS
 * bridge layer.
 */
module.exports = {
  testEnvironment: 'node',
  testMatch: ['<rootDir>/__tests__/**/*.test.ts'],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        // Type-checking already runs separately via `yarn typescript`.
        isolatedModules: true,
      },
    ],
  },
};
