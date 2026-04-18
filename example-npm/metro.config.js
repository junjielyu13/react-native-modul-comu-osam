const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * This example consumes react-native-modul-comu-osam from npm, so no
 * watchFolders / extraNodeModules plumbing is needed — standard
 * node_modules resolution is enough.
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
