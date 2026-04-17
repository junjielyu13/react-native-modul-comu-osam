# CLAUDE.md

Context for future Claude Code sessions working in this repo.

## What this repo is

A React Native library — npm package name **`react-native-modul-comu-osam`** —
that wraps Barcelona City Council's [`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)
(a Kotlin Multiplatform shared module). It exposes four native methods to JS:

- `checkVersionControl(languageCode)` — force / recommended update dialog
- `showRatingDialog(languageCode)` — native rating prompt
- `getDeviceInformation()` — platform name / version / model
- `getAppInformation()` — app name / versionName / versionCode

Supported languages: `ca` / `es` / `en`.

## Repo layout

```
/                                      ← library root (the npm package)
├── src/                               ← TypeScript entry (src/index.ts)
├── android/                           ← Kotlin source + build.gradle
│   └── src/main/java/cat/bcn/osam/reactnative/
├── ios/                               ← Swift source
├── react-native-modul-comu-osam.podspec
├── package.json
├── example/                           ← minimal RN 0.79.1 smoke-test app
└── frontend_rn_app/                   ← original Park Güell app (still uses
                                        its own inline OSAMModule.{kt,swift};
                                        not yet migrated to the library)
```

## Key design decision: Option 3 wrapper injection

OSAMCommons needs five wrappers (`CrashlyticsWrapper`, `PerformanceWrapper`,
`AnalyticsWrapper`, `PlatformUtil`, `MessagingWrapper`) plus a backend endpoint.

**Decision**: the library ships Firebase-backed defaults but lets consumers
swap in custom implementations.

- **Android**: `OSAMConfiguration.wrappersFactory` is a mutable static (mirrors
  iOS). Autolinking instantiates `OSAMPackage()` via its no-arg constructor,
  which reads the factory from `OSAMConfiguration`. Consumers override by
  setting `OSAMConfiguration.wrappersFactory` in `Application.onCreate` before
  the RN bridge starts. Firebase deps are declared `compileOnly` so the
  library AAR doesn't pin versions; the consumer app provides them at runtime.
  If the consumer sets a custom factory, `DefaultOSAMWrappersFactory` is never
  instantiated → Firebase classes are never resolved, so Firebase can be
  omitted entirely. `OSAMCommon` is exposed as `api` (not `implementation`)
  so consumers writing custom wrappers can import `cat.bcn.commonmodule.*`
  directly. `OSAMPackage.kt`'s class header must stay simple (no
  `@JvmOverloads`, no primary-constructor defaults) — the RN autolinking
  regex in `@react-native-community/cli-config-android/findPackageClassName`
  only handles `[\s\w():,]` between the class name and `: ReactPackage`.
- **iOS**: `OSAMConfiguration.wrappersProvider` is a mutable static. Set it
  in `AppDelegate` before the RN bridge starts. On iOS the Firebase pods are
  **always linked** (declared unconditionally in the podspec) because
  CocoaPods subspec selection doesn't play nicely with RN autolinking. To
  drop them entirely, a consumer would have to fork the podspec.

Backend endpoint resolution (defaults):
- Android: reads the `common_module_endpoint` string resource.
- iOS: reads `common_module_endpoint` from `config_keys.plist` in the main bundle.

## Versions

- React Native: **0.79.1**
- React: **19.0.0**
- Kotlin: **2.0.21**
- OSAM upstream: **3.1.0** (tracked as library version `0.1.0`)
- Android: minSdk 26, compileSdk 35, target 35
- iOS: min iOS 13.0

## Native package/module names

- Kotlin package: `cat.bcn.osam.reactnative` (distinct from upstream's
  `cat.bcn.commonmodule`). Key symbols: `OSAMPackage`, `OSAMModule`,
  `OSAMWrappers`, `OSAMWrappersFactory`, `DefaultOSAMWrappersFactory`,
  `OSAMConfiguration`.
- Swift module: `react_native_modul_comu_osam`. Key symbols: `OSAMModule`,
  `OSAMConfiguration`, `OSAMWrappersProvider`, `DefaultOSAMWrappersProvider`.
- React bridge module name (both platforms): `OSAMModule`.

## Example app (`example/`)

Bootstrapped via `npx @react-native-community/cli@18.0.0 init` (so all
standard RN scaffolding is present). Uses **no-op wrappers** registered via
Option 3 so the example runs without any Firebase config. Doubles as a
demo of the wrapper override path.

To exercise `checkVersionControl` / `showRatingDialog` against the real
backend, the example's `applicationId` (Android) and
`PRODUCT_BUNDLE_IDENTIFIER` (iOS) are both set to `cat.bcn.parkguell.altech`,
and the no-op wrappers return `https://dev-osam-modul-comu.dtibcn.cat/`
as `backendEndpoint` — same as `frontend_rn_app/`. Without these two
matching the real app/backend pair, the OSAM calls just return
`status: "ERROR"` because the backend doesn't recognize the identifier.

Run from repo root:
```sh
yarn install                              # library devDeps (installs react-native-builder-bob etc.)
cd example && yarn install                # example + link:.. to the library
yarn android                              # or: cd ios && bundle install && bundle exec pod install && cd .. && yarn ios
```

Test UI in `example/App.tsx` has 4 buttons that call each method and render
the result. Expected results:
- `getAppInformation` / `getDeviceInformation` — green, returns JSON.
- `checkVersionControl('en')` — real backend response from the dev OSAM
  endpoint (`ACCEPTED` / `DISMISS` / `CANCELLED` / no-op depending on current
  remote config for `cat.bcn.parkguell.altech`). `ERROR` only if offline or
  the backend is unreachable.
- `showRatingDialog('en')` — native rating dialog appears.

## frontend_rn_app (original Park Güell app)

Still has its own inline bridging code at:
- `frontend_rn_app/android/app/src/main/java/cat/bcn/parkguell/OSAMModule.kt`
- `frontend_rn_app/android/app/src/main/java/cat/bcn/parkguell/OSAMPackage.kt`
- `frontend_rn_app/ios/frontend_rn_app/OSAMModule.{swift,m}`
- `frontend_rn_app/app/native/OSAMModule.ts` + `types/`

**Not yet migrated** to the library. The library was extracted *from* this
app's code. Migration is a likely follow-up task: delete the inline files
and swap to `import OSAMModule from 'react-native-modul-comu-osam'` +
`add(OSAMPackage())` (with Firebase defaults, since the app already has
Firebase fully configured).

## Progress checklist

Completed:
- [x] Library scaffold (`package.json`, `tsconfig`, `src/index.ts`, `src/types.ts`, `.gitignore`, `.npmignore`)
- [x] Android native module + `DefaultOSAMWrappersFactory` with Firebase
- [x] iOS native module + `DefaultOSAMWrappersProvider` with Firebase + podspec
- [x] README with install/usage/override docs
- [x] `example/` RN 0.79.1 smoke-test app with no-op wrappers

Not yet done:
- [x] **Verify Android compile**: `./gradlew app:compileDebugKotlin` passes
      (autolinking picks up `OSAMPackage` + `:react-native-modul-comu-osam:compileDebugKotlin`).
      `yarn android` end-to-end still needs an emulator / device to confirm install.
- [x] **Verify iOS build**: `xcodebuild … -scheme Example` builds clean.
      `yarn ios` end-to-end still needs a simulator launch to confirm install.
      Consumer Podfile must declare `pod 'OSAMCommon', :git => '…', :tag => '3.1.0'`
      since the dep is not on CocoaPods trunk.
- [ ] Migrate `frontend_rn_app` to consume the library.
- [ ] Publish to a registry (npm? GitHub Packages?). No registry decision yet.
- [ ] CI (none configured).
- [ ] Tests (none — smoke-test is manual via example app).

## Build/publish notes

- `yarn prepare` at root runs `react-native-builder-bob` to emit `lib/`
  (commonjs, module, typescript). Required before publishing.
- Metro consumes `src/index.ts` directly via the `"react-native"` package.json
  field, so `lib/` does **not** need to exist during local dev.
- TypeScript resolution for example uses `"types": "lib/typescript/src/index.d.ts"`,
  which **does** require `yarn prepare` at the root for type-checking the
  example. At runtime Metro uses `src/` regardless.

## Known diagnostics (safe to ignore)

- SourceKit in standalone library files (`ios/*.swift`) reports
  `No such module 'React'` / `'OSAMCommon'` / `'UIKit'`. These resolve only
  when the library is linked into a host app via `pod install`. Expected —
  not a real error.

## Gotchas

- **Don't re-add `"packageManager": "yarn@3.6.4"` to root `package.json`.**
  The RN CLI scaffolder added it when generating `example/`, but it makes
  yarn berry treat the whole repo as a workspace project and rejects `yarn
  install` inside `example/` ("nearest package directory … doesn't seem to
  be part of the project"). Removed from root. `example/yarn.lock` exists
  as an empty file so berry treats example as an independent project.
  `frontend_rn_app/` already has its own `yarn.lock` so it's fine.
- **Don't add `"workspaces": ["example"]` to root `package.json`.** With
  `nodeLinker: node-modules`, yarn berry does NOT create a self-symlink
  (`node_modules/react-native-modul-comu-osam`) for the root workspace,
  so gradle/Metro autolinking can't resolve the library. Example must be
  an independent project (empty `example/yarn.lock`) with
  `react-native.config.js` pointing at `..`.
- **Autolinking bridge: `example/react-native.config.js`** explicitly maps
  `react-native-modul-comu-osam` → repo root. This is the official
  `react-native-builder-bob` pattern and bypasses node_modules resolution
  entirely. Don't rely on `link:..` / `portal:..` to create a node_modules
  symlink — yarn berry + `nodeLinker: node-modules` doesn't materialize
  those protocols as filesystem entries.
- **New Swift files in `example/ios/Example/` must be registered in
  `Example.xcodeproj/project.pbxproj`.** Creating a `.swift` file on disk is
  not enough — Xcode only compiles files listed in `PBXBuildFile` +
  `PBXFileReference` + the Example `PBXGroup` children + `PBXSourcesBuildPhase`.
  If the file is missing from the project, the build fails at link time with
  `cannot find 'ClassName' in scope` in any file that references it. The
  xcodebuild log buries this error deep inside Pods compile output
  (most visibly glog's response files), so searching for `error:` is the
  fast way to find the real cause. `AppDelegate.swift` is a working reference
  for the four entries required.
- **Don't use `@JvmOverloads` on `OSAMPackage`'s primary constructor.**
  RN autolinking's `findPackageClassName` regex
  (`class\s+(\w+[^(\s]*)[\s\w():]*(\s+implements\s+|:)[\s\w():,]*[^{]*ReactPackage`)
  rejects `@`, `=`, and trailing `,` between the class name and `: ReactPackage`.
  If it fails to match, `dependencyConfig` returns `null` and the library is
  NOT added as a gradle subproject — compile fails with "Unresolved reference
  'cat'" for every symbol the consumer tries to import.

## Useful reference paths in `frontend_rn_app/`

If you need to look at how things work in the real app:
- Podfile: `frontend_rn_app/ios/Podfile` (shows `use_frameworks! :linkage => :static`,
  `$RNFirebaseAsStaticFramework = true`, and `pod 'OSAMCommon', :git => '...', :tag => '3.1.0'`).
- Android `build.gradle`: `frontend_rn_app/android/app/build.gradle` (JitPack + Firebase deps).

## Conventions

- Android default backend endpoint via string resource `common_module_endpoint`.
- iOS default backend endpoint via `config_keys.plist` key `common_module_endpoint`.
- The library does not bundle either — the consumer app (or a custom factory) provides it.
