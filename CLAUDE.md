# CLAUDE.md

Context for future Claude Code sessions working in this repo.

## What this repo is

A React Native library — npm package name **`react-native-modul-comu-osam`** —
that wraps Barcelona City Council's [`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)
(a Kotlin Multiplatform shared module). Method names match the upstream
`OSAMCommons` API one-to-one:

- `versionControl(languageCode)` — force / recommended update dialog
- `rating(languageCode)` — native rating prompt
- `deviceInformation()` — platform name / version / model
- `appInformation()` — app name / versionName / versionCode
- `changeLanguageEvent(languageCode)` — log language change, rotate FCM topics
- `firstTimeOrUpdateEvent(languageCode)` — initial / post-update FCM topic setup
- `subscribeToCustomTopic(topic)` / `unsubscribeToCustomTopic(topic)`
- `getFCMToken()` — resolves `{ token }` or rejects

Supported languages: `ca` / `es` / `en`.

Response enum values returned in `.status`:
- versionControl → `ACCEPTED | DISMISSED | CANCELLED | ERROR`
- rating / appInformation → `ACCEPTED | DISMISSED | ERROR`
- deviceInformation → `ACCEPTED | ERROR`
- changeLanguageEvent / firstTimeOrUpdateEvent → `SUCCESS | UNCHANGED | ERROR`
- subscribeToCustomTopic / unsubscribeToCustomTopic → `ACCEPTED | ERROR`

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
│                                        (consumes library via `portal:..`)
└── example-npm/                       ← same app, consumes library from the
                                        published npm package — used to
                                        validate that the tarball uploaded
                                        to npm is complete
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
- OSAM upstream: **3.2.0** (tracked as library version `0.3.0`)
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
standard RN scaffolding is present). Uses the library's **Firebase-backed
default wrappers** (`DefaultOSAMWrappersFactory` / `DefaultOSAMWrappersProvider`),
so the full FCM surface works end-to-end (real `getFCMToken`,
`subscribeToCustomTopic`, analytics, crashlytics, performance).

The example's `applicationId` (Android) and `PRODUCT_BUNDLE_IDENTIFIER` (iOS)
are both set to `cat.bcn.parkguell.altech`. The two Firebase config files
(`google-services.json`, `GoogleService-Info.plist`) are **gitignored** and
must be supplied per-environment — download them from the Firebase console
for an app registered under the same bundle ID.

The backend endpoint (`https://dev-osam-modul-comu.dtibcn.cat/`) is stored
as a **resource**, not hardcoded — mirroring the upstream OSAM convention
(dedicated `config_keys.{xml,plist}` files, symmetric across platforms):
- Android: `example/android/app/src/main/res/values/config_keys.xml` →
  `common_module_endpoint` string.
- iOS: `example/ios/Example/config_keys.plist` → `common_module_endpoint`
  key (registered in `Example.xcodeproj/project.pbxproj` with the same
  4-entry pattern as `GoogleService-Info.plist`, UUID prefix `7617809C/9D…`).

On Android the library's `resolveEndpointFromResources` uses
`Resources.getIdentifier("common_module_endpoint", "string", packageName)`
— lookup is by resource name, not filename, so any `values/*.xml` under
the app works. `config_keys.xml` is preferred purely for symmetry with iOS
and to keep config keys separate from UI strings.

`MainApplication.kt` and `AppDelegate.swift` call the **no-arg**
`DefaultOSAMWrappersFactory()` / `DefaultOSAMWrappersProvider()` so the
endpoint is resolved from those resources at runtime. To redirect the
example at a different backend, edit the two resource files — no Kotlin
/ Swift change needed. Without matching app/backend identifiers, OSAM
calls just return `status: "ERROR"` because the backend doesn't recognize
the identifier.

**Firebase wiring in the example:**
- Android: `example/android/build.gradle` declares the google-services /
  crashlytics / perf-plugin classpath entries; `example/android/app/
  build.gradle` applies the three plugins and declares the Firebase BOM +
  analytics/crashlytics/perf/messaging deps (since the library's Firebase
  deps are `compileOnly`, the consumer app must supply them).
- iOS: the podspec already pulls Firebase Analytics / Crashlytics /
  Performance / Messaging. `AppDelegate.swift` calls `FirebaseApp.configure()`
  before assigning `OSAMConfiguration.wrappersProvider`. The
  `GoogleService-Info.plist` is registered in
  `Example.xcodeproj/project.pbxproj` (`PBXBuildFile` + `PBXFileReference`
  + Example `PBXGroup` children + `PBXResourcesBuildPhase`).

Run from repo root:
```sh
yarn install                              # library devDeps (installs react-native-builder-bob etc.)
cd example && yarn install                # example + link:.. to the library
yarn android                              # or: cd ios && bundle install && bundle exec pod install && cd .. && yarn ios
```

Test UI in `example/App.tsx` has 10 buttons (one per OSAMCommons method, plus `isOnline`).
Expected results:
- `appInformation` / `deviceInformation` — green, returns JSON.
- `versionControl('en')` — real backend response from the dev OSAM
  endpoint (`ACCEPTED` / `DISMISSED` / `CANCELLED` depending on current
  remote config for `cat.bcn.parkguell.altech`). `ERROR` only if offline or
  the backend is unreachable.
- `rating('en')` — native rating dialog appears.
- `changeLanguageEvent` / `firstTimeOrUpdateEvent` — `SUCCESS` / `UNCHANGED`.
- `subscribeToCustomTopic` / `unsubscribeToCustomTopic` — `ACCEPTED`.
- `getFCMToken` — returns a real FCM registration token (not `noop-token`).

## Example app (`example-npm/`)

Same UI and Firebase wiring as `example/`, but its `package.json` depends on
`react-native-modul-comu-osam@^0.3.0` from the **public npm registry**
instead of the local `portal:..` workspace. Because the library resolves
through normal `node_modules`, this variant:

- has **no** `react-native.config.js` (RN autolinking finds the package
  natively under `node_modules/react-native-modul-comu-osam/`),
- has a **plain** `metro.config.js` (no `watchFolders` / `extraNodeModules`
  / `blockList` plumbing),
- does **not** require `yarn install` + `yarn prepare` at the repo root
  before building (nothing is symlinked in from the workspace).

Purpose: verify the *published* tarball actually ships everything needed
(`src/`, `lib/`, `android/`, `ios/`, the `.podspec`) — this is what catches
missing files in `package.json#files` or a stale `yarn prepare` before a
release. Edits to library sources are **not** reflected here until a new
version is published. For day-to-day library development keep using
`example/`.

Run:
```sh
cd example-npm && yarn install
yarn android                              # or: cd ios && bundle install && bundle exec pod install && cd .. && yarn ios
```

Firebase config files (`google-services.json` / `GoogleService-Info.plist`)
follow the same convention as `example/` — supply your own per-environment
copies. Bundle ID is identical (`cat.bcn.parkguell.altech`), so the same
Firebase project and the same dev OSAM backend serve both examples.

## Progress checklist

Completed:
- [x] Library scaffold (`package.json`, `tsconfig`, `src/index.ts`, `src/types.ts`, `.gitignore`, `.npmignore`)
- [x] Android native module + `DefaultOSAMWrappersFactory` with Firebase
- [x] iOS native module + `DefaultOSAMWrappersProvider` with Firebase + podspec
- [x] README with install/usage/override docs
- [x] `example/` RN 0.79.1 smoke-test app with Firebase-backed default wrappers
- [x] `example-npm/` — same smoke-test app but consuming the library from the
      published npm package, for validating the tarball before/after a release

Not yet done:
- [x] **Verify Android compile**: `./gradlew app:compileDebugKotlin` passes
      (autolinking picks up `OSAMPackage` + `:react-native-modul-comu-osam:compileDebugKotlin`).
      `yarn android` end-to-end still needs an emulator / device to confirm install.
- [x] **Verify iOS build**: `xcodebuild … -scheme Example` builds clean.
      `yarn ios` end-to-end still needs a simulator launch to confirm install.
      Consumer Podfile must declare `pod 'OSAMCommon', :git => '…', :tag => '3.2.0'`
      since the dep is not on CocoaPods trunk.
- [x] **Publish to npm** as the public unscoped package
      `react-native-modul-comu-osam`. Release process documented in
      `PUBLISHING.md` (version bump locations, `yarn prepare` → `npm pack` →
      `npm publish` → `v<version>` git tag → `example-npm/` smoke test).
- [ ] CI (none configured). All four planned pieces — JS checks, Android library compile, iOS example build, tag-triggered npm publish — are documented in `CI.md` along with rollout order and a combined implementation checklist.
- [x] **Unit tests for the JS bridge** (`__tests__/index.test.ts`,
      `__tests__/linking-error.test.ts`, `yarn test`). Cover argument
      passthrough, the `versionControl` / `rating` default-arg substitution,
      response passthrough, the `OSAMResultEnum` surface, and the
      `LINKING_ERROR` proxy. Native (Kotlin / Swift) layers and FCM /
      backend integration are still smoke-tested manually via the example
      apps — Robolectric / XCTest unit tests on the wrappers haven't been
      written (very low ROI for a thin forwarding layer).

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
  be part of the project"). Removed from root. `example/yarn.lock` and
  `example-npm/yarn.lock` exist as empty files so berry treats each example
  as an independent project.
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

## Conventions

- Android default backend endpoint via string resource `common_module_endpoint`.
- iOS default backend endpoint via `config_keys.plist` key `common_module_endpoint`.
- The library does not bundle either — the consumer app (or a custom factory) provides it.
