# Example app — `react-native-modul-comu-osam` (npm)

Same nine-button smoke-test UI as `../example/`, but consumes the library
from **npm** (`react-native-modul-comu-osam@^0.2.0` on the public registry)
instead of the local workspace.

The point of this variant is to exercise the *published* consumer path: it
verifies that the tarball uploaded to npm is complete (that `.npmignore` /
`files` / `lib/` build outputs cover everything needed) and that an
out-of-the-box RN project can install and run the library without any
local plumbing.

Treat `../example/` as the development example (edit library sources, see
changes immediately). Treat this one as the **pre-publish / post-publish
smoke check**.

Upstream OSAM project:
[AjuntamentdeBarcelona/modul_comu_osam](https://github.com/AjuntamentdeBarcelona/modul_comu_osam).

Uses the library's **Firebase-backed default wrappers**
(`DefaultOSAMWrappersFactory` / `DefaultOSAMWrappersProvider`), so the full
FCM surface works end-to-end (real `getFCMToken`, `subscribeToCustomTopic`,
analytics, crashlytics, performance).

> **Why `cat.bcn.parkguell.altech`?** It's the bundle identifier registered
> with the dev OSAM backend for the Park Güell demo app — that's the only
> reason it works out of the box here. **For your own app, choose your own
> identifier and confirm with the OSAM team** so it can be registered on
> the backend; otherwise every OSAM call will come back as
> `status: "ERROR"`.

The example's `applicationId` (Android) and `PRODUCT_BUNDLE_IDENTIFIER` (iOS)
are both `cat.bcn.parkguell.altech`, and the OSAM backend endpoint is stored
as a **resource** (not hardcoded) — at
`android/app/src/main/res/values/config_keys.xml` (`common_module_endpoint`
string) and `ios/Example/config_keys.plist` (`common_module_endpoint`
key) — mirroring the upstream OSAM convention. To point the example at a different backend, edit those two files
instead of `MainApplication.kt` / `AppDelegate.swift`. The default value is
`https://dev-osam-modul-comu.dtibcn.cat/` (the shared dev endpoint).

## Prerequisites

- Node / Yarn (Berry — `yarn-3.6.4` is pinned via `.yarnrc.yml`)
- Xcode + CocoaPods + Ruby bundler (for iOS)
- Android Studio / Android SDK + an emulator or device (for Android)
- **A Firebase project** with apps registered under bundle ID
  `cat.bcn.parkguell.altech` (both Android and iOS)

## Drop in the Firebase config files

The two files below are **gitignored** because they identify a specific
Firebase project. Supply your own before building:

| Platform | Destination |
|---|---|
| Android | `example-npm/android/app/google-services.json` |
| iOS | `example-npm/ios/Example/GoogleService-Info.plist` |

### Where to get them

1. Firebase console → Project settings → your Android app
   (`cat.bcn.parkguell.altech`) → *Download `google-services.json`*.
2. Firebase console → Project settings → your iOS app
   (`cat.bcn.parkguell.altech`) → *Download `GoogleService-Info.plist`*.

### iOS — the plist is already registered in `project.pbxproj`

The Xcode project already references a file at
`Example/GoogleService-Info.plist` (PBXFileReference + PBXGroup children
+ PBXResourcesBuildPhase entries, UUID prefix `761780…`). Just dropping
the `.plist` at that path is enough — no Xcode GUI step needed.

If you later rename or move the plist, re-register it: drag-and-drop the
file into the Example target in the Xcode navigator and Xcode patches
`project.pbxproj` automatically.

## Run

Unlike `../example/`, this variant does **not** need `yarn install` at the
repo root — it pulls the library straight from npm. Just:

```sh
cd example-npm
yarn install          # installs react-native-modul-comu-osam from npm
```

### Android

```sh
yarn android
```

First build pulls `com.github.AjuntamentdeBarcelona.modul_comu_osam:common-android:3.1.0`
from JitPack, plus the Firebase BOM / analytics / crashlytics / perf / messaging
artifacts.

### iOS

```sh
cd ios
bundle install
bundle exec pod install
cd ..
yarn ios
```

First `pod install` pulls `OSAMCommon` (from the upstream git repo) and the
four Firebase pods.

## What each button does

| Button | Expected result |
|---|---|
| `appInformation()` | `{ appName, appVersionName, appVersionCode }` — local, always `ACCEPTED`. |
| `deviceInformation()` | `{ platformName, platformVersion, platformModel }` — local, always `ACCEPTED`. |
| `versionControl('en')` | Real dev-backend response — `ACCEPTED` / `DISMISSED` / `CANCELLED` depending on the backend's current config for `cat.bcn.parkguell.altech`. `ERROR` only if offline / backend unreachable. |
| `rating('en')` | Native rating dialog (or `DISMISSED` if shown recently). |
| `changeLanguageEvent('es')` | `SUCCESS` on first call, `UNCHANGED` if the language already matches. |
| `firstTimeOrUpdateEvent('en')` | `SUCCESS` the first time, `UNCHANGED` after. |
| `subscribeToCustomTopic('demo')` | `ACCEPTED` — FCM registers the topic for the device. |
| `unsubscribeToCustomTopic('demo')` | `ACCEPTED`. |
| `getFCMToken()` | Real FCM registration token (long base64-ish string). |

## Troubleshooting

- **Android build fails at `:app:processDebugGoogleServices`** — the
  `google-services.json` is missing, or its `package_name` doesn't match
  `cat.bcn.parkguell.altech`.
- **iOS crashes at launch inside `FirebaseApp.configure()`** — the
  `GoogleService-Info.plist` is missing from the built bundle. Check
  Example target → *Build Phases → Copy Bundle Resources*.
- **All OSAM calls return `status: 'ERROR'`** — either offline, or the
  bundle ID of the built app doesn't match what the dev OSAM backend has
  registered.
- **`getFCMToken()` returns `"noop-token"`** — `MainApplication.kt` /
  `AppDelegate.swift` is still registering `NoopWrappersFactory` /
  `NoopWrappersProvider`. Switch to `DefaultOSAMWrappersFactory` /
  `DefaultOSAMWrappersProvider`.

## Swapping Firebase out

If you'd rather not ship Firebase, the library supports plugging in custom
wrappers — see the **Overriding the default wrappers** section of the repo-root
`README.md`. The previous version of this example used a `NoopWrappersFactory`
/ `NoopWrappersProvider` demonstrating that path; `git log` has the history.
