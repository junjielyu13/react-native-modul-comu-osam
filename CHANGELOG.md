# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-05-04

Tracks upstream **OSAM 3.2.0**.

### Added

- `isOnline()` — reachability probe added in OSAM 3.2.0. Resolves with
  `{ online: boolean }` and never rejects.
- `versionControl` / `rating` now accept the two optional dialog params
  added in OSAM 3.2.0: `isDarkMode` (default `false`) and
  `applyComModStyles` (default `true`).
- `debug` flag on `DefaultOSAMWrappersFactory` (Android) /
  `DefaultOSAMWrappersProvider` (iOS). When enabled, internal failure
  paths (silent `openUrl` failures, missing `common_module_endpoint`,
  FCM errors) are reported to Crashlytics as breadcrumbs / non-fatals
  under the `OSAMReactNativeDebug` domain. Defaults to `false` so
  production apps stay silent. URLs in breadcrumbs are redacted to
  `scheme://host/path`; topic names are logged in plain text.
- `.github/CODEOWNERS` enforces admin review on `main` / `dev`.

### Changed

- Native init is now resilient: invalid/missing `common_module_endpoint`,
  malformed FCM topic strings, and Firebase-spec violations no longer
  crash the bridge — they surface as `status: "ERROR"` (or, with
  `debug: true`, as Crashlytics non-fatals).
- Android `OSAMCommon` dependency bumped from 3.1.0 → 3.2.0
  (`com.github.AjuntamentdeBarcelona.modul_comu_osam:common-android`).
- iOS podspec dependency bumped from `OSAMCommon ~> 3.1.0` to `~> 3.2.0`.
  Consumer Podfiles must re-pin the upstream tag:
  `pod 'OSAMCommon', :git => '…', :tag => '3.2.0'`.
- TypeScript: `OSAMStatusResponse.status` is now strictly typed as                                                                    
  `${OSAMResultEnum}` (the previous `| string` widening made the                                                                      
  template-literal half useless). Consumers comparing against arbitrary                                                               
  strings should switch to `OSAMResultEnum` constants.                                                                                
- iOS `DefaultOSAMWrappersProvider` now caches `backendEndpoint` after                                                                
  the first non-empty plist read (perf only — empty results are not                                                                   
  cached, so the graceful-init contract is preserved).

## [0.2.1] — 2026-04-18

### Added

- Catalan translation of the README (`README.ca.md`).
- `example-npm/` consumer app that installs the library from the public
  npm registry, used to validate the published tarball before/after a
  release.

### Fixed

- `react-native-modul-comu-osam.podspec` source `:git` URL and `:tag`
  format (`v<version>`) so `pod install` resolves the tag published on
  GitHub.

### Changed

- Package metadata polish (`package.json` description / keywords) and
  CHANGELOG formatting.

## [0.2.0] — 2026-04-17

### Added

- Complete upstream `OSAMCommons` API surface wired through both platforms:
  - `versionControl(languageCode)`
  - `rating(languageCode)`
  - `deviceInformation()`
  - `appInformation()`
  - `changeLanguageEvent(languageCode)`
  - `firstTimeOrUpdateEvent(languageCode)`
  - `subscribeToCustomTopic(topic)` / `unsubscribeToCustomTopic(topic)`
  - `getFCMToken()`
- Firebase-backed default wrappers (`DefaultOSAMWrappersFactory` on Android,
  `DefaultOSAMWrappersProvider` on iOS) covering Crashlytics, Performance,
  Analytics, and Messaging. Swappable at runtime via
  `OSAMConfiguration.wrappersFactory` / `.wrappersProvider`.
- Per-platform backend endpoint resolution via resources:
  - Android: `common_module_endpoint` string resource (any `values/*.xml`).
  - iOS: `common_module_endpoint` key in a `config_keys.plist` bundled in the
    app — mirrors the upstream OSAM convention.
- iOS Push Notifications setup documentation (Xcode capabilities, APNS
  wiring in `AppDelegate`, Firebase Console APNs auth key) — required for
  the FCM methods to work on iOS.
- Example app (`example/`) switched off no-op wrappers to use the Firebase
  defaults, so the full FCM surface works end-to-end against the dev OSAM
  backend.

### Changed

- Example app now runs with real Firebase configuration; consumers must
  supply `google-services.json` / `GoogleService-Info.plist` per environment.

## [0.1.1] — 2026-04-17

### Fixed

- Podspec: read `s.homepage` from `package["homepage"]` instead of
  `package["repository"]` (which is a Hash in the current `package.json`),
  unblocking `pod install` in consumer apps.

## [0.1.0] — 2026-04-17

### Added

- Initial library scaffold wrapping Barcelona City Council's
  [`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)
  KMP module for React Native.
- Android native module (`cat.bcn.osam.reactnative`) and iOS native module
  (`react_native_modul_comu_osam`), both exposed to JS as `OSAMModule`.
- Option-3 wrapper injection: library ships Firebase-backed defaults but
  lets consumers swap in custom `CrashlyticsWrapper` / `PerformanceWrapper`
  / `AnalyticsWrapper` / `PlatformUtil` / `MessagingWrapper` implementations.
- Example app (`example/`) with no-op wrappers so it runs without Firebase
  configuration.

[0.3.0]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.3.0
[0.2.1]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.2.1
[0.2.0]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.2.0
[0.1.1]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.1.1
[0.1.0]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.1.0
