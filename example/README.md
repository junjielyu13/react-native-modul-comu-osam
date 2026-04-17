# Example app — `react-native-modul-comu-osam`

Minimal React Native 0.79 app that smoke-tests the four native methods.

Uses **no-op wrappers** (Option 3 override), so it does **not** require
Firebase configuration (`google-services.json` / `GoogleService-Info.plist`).

To exercise `checkVersionControl` / `showRatingDialog` against the real
Park Güell configuration, the example's `applicationId` / bundle ID is
`cat.bcn.parkguell.altech` and the no-op wrappers return
`https://dev-osam-modul-comu.dtibcn.cat/` as `backendEndpoint` — the
same values used by `frontend_rn_app/`. Change those two constants to
point the example at a different app/backend.

## Run

From the **repo root**:

```sh
yarn install        # installs library devDeps
cd example
yarn install        # installs example + links parent library
```

### Android

```sh
yarn android
```

First build pulls `com.github.AjuntamentdeBarcelona.modul_comu_osam:common-android:3.1.0`
from JitPack (already configured in `android/build.gradle`).

### iOS

```sh
cd ios && bundle install && bundle exec pod install && cd ..
yarn ios
```

First `pod install` pulls `OSAMCommon` and the (unused) Firebase pods.

## What each button does

- `getAppInformation()` — local call, should return the example app's bundle info.
- `getDeviceInformation()` — local call, should return device platform/version/model.
- `checkVersionControl('en')` — hits `https://dev-osam-modul-comu.dtibcn.cat/`
  with `applicationId` `cat.bcn.parkguell.altech`, so a real backend response
  comes back (`ACCEPTED` / `DISMISS` / `CANCELLED` depending on current
  remote config for that app). If the device is offline or the backend is
  unreachable the status is `ERROR`.
- `showRatingDialog('en')` — triggers the native rating dialog.

## Switching to real Firebase wrappers

Drop the `NoopWrappersFactory(...)` / `NoopWrappersProvider()` registration and
let the default `DefaultOSAMWrappersFactory` / `DefaultOSAMWrappersProvider`
kick in. You'll then need to:

- Place `google-services.json` under `android/app/` and apply the google-services
  / crashlytics / perf Gradle plugins.
- Place `GoogleService-Info.plist` in `ios/Example/` and call
  `FirebaseApp.configure()` in `AppDelegate`.
- Provide a `common_module_endpoint` string resource (Android) and
  `config_keys.plist` entry (iOS) pointing at your OSAM backend.
