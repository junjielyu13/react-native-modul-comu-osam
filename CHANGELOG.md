# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.2.1]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.2.1
[0.2.0]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.2.0
[0.1.1]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.1.1
[0.1.0]: https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v0.1.0
