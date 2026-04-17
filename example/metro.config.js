const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const path = require('path');
const pak = require('../package.json');

const root = path.resolve(__dirname, '..');
const peerDeps = Object.keys(pak.peerDependencies || {});

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * Makes the example resolve the library directly from the repo root and
 * avoids duplicate copies of peer dependencies (react, react-native).
 * The library isn't materialized in `example/node_modules/` because yarn
 * berry's `portal:` protocol + `nodeLinker: node-modules` doesn't create
 * filesystem entries, so we map it explicitly via `extraNodeModules`.
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {
  projectRoot: __dirname,
  watchFolders: [root],
  resolver: {
    blockList: peerDeps.map(
      (name) =>
        new RegExp(`^${escape(path.join(root, 'node_modules', name))}\\/.*$`)
    ),
    extraNodeModules: {
      ...peerDeps.reduce((acc, name) => {
        acc[name] = path.join(__dirname, 'node_modules', name);
        return acc;
      }, {}),
      [pak.name]: root,
    },
  },
};

function escape(str) {
  return str.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');
}

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
