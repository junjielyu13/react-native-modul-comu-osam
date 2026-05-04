# react-native-modul-comu-osam

> 📘 També disponible en [català](./README.ca.md).

React Native bridge for the Barcelona City Council common module — upstream
project: **[AjuntamentdeBarcelona/modul_comu_osam](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)**
(Kotlin Multiplatform). This library wraps the upstream `OSAMCommons` API one-to-one
and exposes it to React Native.

> **Important — bundle ID / applicationId registration.** The OSAM backend
> only responds to apps whose bundle identifier (iOS) / applicationId
> (Android) has been pre-registered on the backend side. Before you ship,
> **confirm the identifier with the OSAM team** so it can be registered —
> otherwise every `versionControl` / `rating` / lifecycle call comes back
> with `status: "ERROR"`. The identifier used throughout this repo
> (`cat.bcn.parkguell.altech`) is an **example only** — it's the one
> registered for the Park Güell demo app, not a value you should reuse.

Exposes all ten `OSAMCommons` operations to JavaScript with the same method
names as the upstream library:

| Method | Returns | Status values |
|---|---|---|
| `versionControl(languageCode, isDarkMode?, applyComModStyles?)` | `{ status }` | `ACCEPTED` · `DISMISSED` · `CANCELLED` · `ERROR` |
| `rating(languageCode, isDarkMode?, applyComModStyles?)` | `{ status }` | `ACCEPTED` · `DISMISSED` · `ERROR` |
| `deviceInformation()` | `{ platformName, platformVersion, platformModel }` | — |
| `appInformation()` | `{ appName, appVersionName, appVersionCode }` | — |
| `changeLanguageEvent(languageCode)` | `{ status }` | `SUCCESS` · `UNCHANGED` · `ERROR` |
| `firstTimeOrUpdateEvent(languageCode)` | `{ status }` | `SUCCESS` · `UNCHANGED` · `ERROR` |
| `subscribeToCustomTopic(topic)` | `{ status }` | `ACCEPTED` · `ERROR` |
| `unsubscribeToCustomTopic(topic)` | `{ status }` | `ACCEPTED` · `ERROR` |
| `getFCMToken()` | `{ token }` | rejects on failure |
| `isOnline()` | `{ online }` | `true` · `false` (never rejects) |

Supported language codes: `ca` · `es` · `en`.

`versionControl` and `rating` accept two optional booleans added in upstream
3.2.0: `isDarkMode` (default `false`) and `applyComModStyles` (default `true`).

## Installation

```sh
yarn add react-native-modul-comu-osam
# or
npm install react-native-modul-comu-osam
```

The library ships **Firebase-backed default wrappers** (Crashlytics,
Performance, Analytics, Messaging). Consumer apps must either:

1. Provide Firebase and a `config_keys.{xml,plist}` backend endpoint
   (covered below), **OR**
2. Swap in a custom wrapper implementation
   ([Overriding the default wrappers](#overriding-the-default-wrappers)).

---

## iOS setup

### 1. Podfile

`OSAMCommon` isn't on CocoaPods trunk — declare it from the upstream git
repo, and enforce static linkage (Firebase recommends it, and OSAMCommon
ships as a static framework):

```ruby
target 'YourApp' do
  pod 'OSAMCommon',
    :git => 'https://github.com/AjuntamentdeBarcelona/modul_comu_osam.git',
    :tag => '3.2.0'

  use_frameworks! :linkage => :static
  $RNFirebaseAsStaticFramework = true

  # …use_react_native!…
end
```

Then install:

```sh
cd ios && bundle install && bundle exec pod install
```

The podspec pulls in `FirebaseAnalytics` / `FirebaseCrashlytics` /
`FirebasePerformance` / `FirebaseMessaging` automatically.

### 2. Firebase config

Drop `GoogleService-Info.plist` into the app target and make sure it's
listed under the target's *Build Phases → Copy Bundle Resources*.
Drag-and-dropping into the Xcode navigator handles this automatically.

### 3. Backend endpoint (`config_keys.plist`)

Create `config_keys.plist` in the app target with a `common_module_endpoint`
key:

```xml
<!-- ios/<YourApp>/config_keys.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>common_module_endpoint</key>
  <string>https://your-osam-backend.example.com</string>
</dict>
</plist>
```

Same as `GoogleService-Info.plist`, ensure it's included in *Copy Bundle
Resources*.

### 4. `AppDelegate.swift`

```swift
import FirebaseCore
import react_native_modul_comu_osam

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: …) -> Bool {
  FirebaseApp.configure()
  OSAMConfiguration.wrappersProvider = DefaultOSAMWrappersProvider()

  // …start RN…
}
```

> Prefer to hard-code the endpoint instead of reading `config_keys.plist`?
> Pass it to the constructor:
> `DefaultOSAMWrappersProvider(backendEndpoint: "https://…")`.

> Want internal failure paths (invalid URL strings, FCM errors,
> missing `common_module_endpoint`, etc.) reported to Crashlytics?
> Pass `debug: true`:
> `DefaultOSAMWrappersProvider(backendEndpoint: nil, debug: true)`.
> Defaults to `false` so production apps stay silent. Silent-failure
> sites (`createMetric` returning `nil`, `openUrl` returning `false`,
> missing `common_module_endpoint`) upload as **non-fatals** under the
> `OSAMReactNativeDebug` error domain. FCM errors (`getFCMToken`,
> `subscribeToCustomTopic`, `unsubscribeToCustomTopic`) are re-recorded
> with their original Firebase error type — they still propagate to
> JS as before.
>
> URLs in breadcrumbs are redacted to `scheme://host/path` (query and
> fragment stripped) so any tokens or PII in query strings don't leave
> the device. **Custom topic names**, however, are logged in plain text
> to Crashlytics on FCM failures — keep PII out of topic names if you
> enable `debug` in production.

### 5. Push Notifications (required for FCM features)

The FCM methods (`getFCMToken`, `subscribeToCustomTopic`,
`unsubscribeToCustomTopic`) only work after iOS has obtained an **APNS
token** and handed it to Firebase Messaging. Without this, `getFCMToken`
rejects with `No APNS token specified before fetching FCM token` and
topic subscriptions silently fail. This is an iOS-only requirement —
Android's FCM path doesn't go through APNS.

Skip this section if you only use non-FCM methods
(`versionControl` / `rating` / `deviceInformation` / `appInformation` /
`changeLanguageEvent` / `firstTimeOrUpdateEvent`) or if you've swapped
in a custom `OSAMWrappersProvider` that doesn't use FCM.

**a. Xcode capabilities.** Open your `.xcworkspace`, select the app
target → *Signing & Capabilities*:

- `+ Capability` → **Push Notifications** (generates `<YourApp>.entitlements`
  with `aps-environment = development`).
- `+ Capability` → **Background Modes** → tick **Remote notifications**.
- Under *Signing*, pick a Team (required for push entitlements to take effect).

**b. Firebase Console.** Upload an APNs Authentication Key (`.p8`) for
your bundle ID under *Project Settings → Cloud Messaging → Apple app
configuration*. Without it, APNS tokens are obtained but Firebase can't
exchange them for FCM tokens.

**c. Extend `AppDelegate.swift`** to request permission, register with
APNS, and forward the device token to Firebase:

```swift
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import react_native_modul_comu_osam

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: …) -> Bool {
    FirebaseApp.configure()

    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { _, _ in }
    application.registerForRemoteNotifications()

    OSAMConfiguration.wrappersProvider = DefaultOSAMWrappersProvider()
    // …start RN…
  }

  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  func application(_ application: UIApplication,
                   didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("APNS registration failed: \(error)")
  }
}
```

**d. Test target.** iOS Simulators **< 16** cannot obtain APNS tokens —
use an iOS 16+ Simulator or a physical device. APNS registration is
asynchronous, so give it a second or two after launch before calling
`getFCMToken` / `subscribeToCustomTopic`.

---

## Android setup

### 1. JitPack

The library pulls `common-android` (the OSAM artifact) from JitPack. Add
the repo to `settings.gradle` (or root `build.gradle`):

```gradle
allprojects {
  repositories {
    maven { url "https://jitpack.io" }
  }
}
```

`OSAMPackage` is picked up by React Native autolinking — no manual
package registration needed.

### 2. Firebase plugins & dependencies

The library's Firebase deps are `compileOnly`, so the consumer app must
supply them at runtime.

Project-level `build.gradle`:

```gradle
buildscript {
  dependencies {
    classpath("com.google.gms:google-services:4.4.2")
    classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.3")
    classpath("com.google.firebase:perf-plugin:1.4.2")
  }
}
```

`android/app/build.gradle`:

```gradle
apply plugin: "com.google.gms.google-services"
apply plugin: "com.google.firebase.crashlytics"
apply plugin: "com.google.firebase.firebase-perf"

dependencies {
  implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
  implementation("com.google.firebase:firebase-analytics")
  implementation("com.google.firebase:firebase-crashlytics")
  implementation("com.google.firebase:firebase-perf")
  implementation("com.google.firebase:firebase-messaging")
}
```

### 3. Firebase config

Drop `google-services.json` into `android/app/`.

### 4. Backend endpoint (`config_keys.xml`)

Create `android/app/src/main/res/values/config_keys.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <string name="common_module_endpoint" translatable="false">https://your-osam-backend.example.com</string>
</resources>
```

The library looks up the resource by **name** (`common_module_endpoint`),
not by filename — any `res/values/*.xml` with that `<string>` entry works.
`config_keys.xml` is the recommended location to stay symmetric with iOS
and keep config keys separate from UI strings. `translatable="false"`
tells Android lint this is a config constant.

### 5. `Application.onCreate`

Set the wrappers factory **before** `SoLoader.init`:

```kotlin
import cat.bcn.osam.reactnative.DefaultOSAMWrappersFactory
import cat.bcn.osam.reactnative.OSAMConfiguration

override fun onCreate() {
  super.onCreate()
  OSAMConfiguration.wrappersFactory = DefaultOSAMWrappersFactory()
  SoLoader.init(this, OpenSourceMergedSoMapping)
}
```

> Prefer to hard-code the endpoint instead of reading `config_keys.xml`?
> Pass it to the constructor:
> `DefaultOSAMWrappersFactory(backendEndpoint = "https://…")`.

> Want internal failure paths (`startActivity` with no handler, FCM
> errors, missing `common_module_endpoint`, etc.) reported to
> Crashlytics? Pass `debug = true`:
> `DefaultOSAMWrappersFactory(debug = true)`.
> Defaults to `false` so production apps stay silent. Silent-failure
> sites (`openUrl` swallowing exceptions from `startActivity`) and FCM
> errors (`getFCMToken`, `subscribeToCustomTopic`,
> `unsubscribeToCustomTopic`) record the caught exception as a
> **non-fatal** event — FCM errors still propagate to JS as before.
> Fatal-path sites (missing endpoint → `IllegalStateException`) only
> attach a breadcrumb, since the resulting crash itself surfaces them.
>
> URLs in breadcrumbs are redacted to `scheme://host/path` (query and
> fragment stripped) so any tokens or PII in query strings don't leave
> the device. **Custom topic names**, however, are logged in plain text
> to Crashlytics on FCM failures — keep PII out of topic names if you
> enable `debug` in production.

---

## Usage

```ts
import OSAMModule, { OSAMResultEnum } from 'react-native-modul-comu-osam';

// Force / recommended update dialog.
const { status } = await OSAMModule.versionControl('en');
if (status === OSAMResultEnum.ACCEPTED) { /* user updated */ }

// …or with the 3.2.0 dialog options (positional):
await OSAMModule.versionControl(
  'en',
  true,  // isDarkMode — optional, default false
  true,  // applyComModStyles — optional, default true
);
await OSAMModule.rating('en', true, false);

// Periodic rating prompt.
await OSAMModule.rating('en');

// Device / app metadata.
const device = await OSAMModule.deviceInformation();
const app = await OSAMModule.appInformation();

// Language / lifecycle events (call on app launch and on user language change).
await OSAMModule.firstTimeOrUpdateEvent('en');
await OSAMModule.changeLanguageEvent('es');

// FCM.
await OSAMModule.subscribeToCustomTopic('park-guell-news');
await OSAMModule.unsubscribeToCustomTopic('park-guell-news');
const { token } = await OSAMModule.getFCMToken();

// Reachability probe (added in 3.2.0). Resolves with `{ online }` —
// never rejects, so it's safe to call without a try/catch.
const { online } = await OSAMModule.isOnline();
```

---

## Overriding the default wrappers

All five wrappers (`Crashlytics`, `Performance`, `Analytics`, `PlatformUtil`,
`Messaging`) are pluggable. Use this path when you don't want Firebase,
or want to route analytics / crash reporting to a different SDK. The
`OSAMWrappers` / `OSAMWrappersProvider` interfaces you implement are
described in `android/src/main/java/cat/bcn/osam/reactnative/OSAMWrappers.kt`
and `ios/OSAMWrappersProvider.swift`.

### Android

```kotlin
import cat.bcn.osam.reactnative.OSAMConfiguration
import cat.bcn.osam.reactnative.OSAMWrappers
import cat.bcn.osam.reactnative.OSAMWrappersFactory

class MyWrappersFactory : OSAMWrappersFactory {
  override fun create(context: Context) = OSAMWrappers(
    crashlytics = MyCrashlyticsWrapper(),
    performance = MyPerformanceWrapper(),
    analytics = MyAnalyticsWrapper(),
    platformUtil = MyPlatformUtil(context),
    messaging = MyMessagingWrapper(),
    backendEndpoint = "https://your-backend.example.com",
  )
}

override fun onCreate() {
  super.onCreate()
  OSAMConfiguration.wrappersFactory = MyWrappersFactory()
  SoLoader.init(this, OpenSourceMergedSoMapping)
}
```

If no custom factory is set, `DefaultOSAMWrappersFactory` (Firebase-backed)
is used. The default factory resolves Firebase classes only when it's
actually instantiated, so a consumer that **always** installs a custom
factory can omit Firebase entirely.

### iOS

```swift
import react_native_modul_comu_osam

class MyProvider: NSObject, OSAMWrappersProvider {
  var backendEndpoint: String { "https://your-backend.example.com" }
  func makeCrashlyticsWrapper() -> CrashlyticsWrapper { MyCrashlytics() }
  func makePerformanceWrapper() -> PerformanceWrapper { MyPerformance() }
  func makeAnalyticsWrapper() -> AnalyticsWrapper { MyAnalytics() }
  func makePlatformUtil() -> PlatformUtil { MyPlatformUtil() }
  func makeMessagingWrapper() -> MessagingWrapper { MyMessaging() }
}

OSAMConfiguration.wrappersProvider = MyProvider()
```

> ⚠️ On iOS the Firebase pods are always linked because they're declared
> unconditionally in the podspec. Overriding the provider stops them from
> running, but doesn't drop the binary. To remove them entirely, fork the
> podspec.

---

## Example apps

Two smoke-test apps are included, both exercising all ten methods
against the real dev OSAM backend:

- [`example/`](./example/README.md) — consumes the library directly from
  this workspace (`portal:..`). Use this for **library development** —
  edits to `src/` / `android/` / `ios/` are picked up immediately.
- [`example-npm/`](./example-npm/README.md) — consumes the library from
  the **published npm package**. Use this as a **pre/post-publish smoke
  check** to confirm the tarball on npm actually works.

Both apps hard-code `cat.bcn.parkguell.altech` as their bundle ID / applicationId,
because that's the identifier the shared dev backend recognizes.
**This is the example's choice, not a reusable default** — for your own
app, see the note near the top of this file about registering your
identifier with the OSAM team.

Firebase configs (`google-services.json` / `GoogleService-Info.plist`)
are gitignored — drop in your own Firebase project matching the bundle
ID you actually plan to use.

---

## API

```ts
interface OSAMModuleInterface {
  versionControl(
    languageCode: 'ca' | 'es' | 'en' | string,
    isDarkMode?: boolean,        // default: false
    applyComModStyles?: boolean, // default: true
  ): Promise<{ status: string }>;
  rating(
    languageCode: 'ca' | 'es' | 'en' | string,
    isDarkMode?: boolean,        // default: false
    applyComModStyles?: boolean, // default: true
  ): Promise<{ status: string }>;
  deviceInformation():
    Promise<{ platformName: string; platformVersion: string; platformModel: string }>;
  appInformation():
    Promise<{ appName: string; appVersionName: string; appVersionCode: string }>;
  changeLanguageEvent(languageCode: 'ca' | 'es' | 'en' | string):
    Promise<{ status: string }>;
  firstTimeOrUpdateEvent(languageCode: 'ca' | 'es' | 'en' | string):
    Promise<{ status: string }>;
  subscribeToCustomTopic(topic: string):
    Promise<{ status: string }>;
  unsubscribeToCustomTopic(topic: string):
    Promise<{ status: string }>;
  getFCMToken():
    Promise<{ token: string }>;
  isOnline():
    Promise<{ online: boolean }>;
}

enum OSAMResultEnum {
  ACCEPTED = 'ACCEPTED',
  DISMISSED = 'DISMISSED',
  CANCELLED = 'CANCELLED',
  SUCCESS = 'SUCCESS',
  UNCHANGED = 'UNCHANGED',
  ERROR = 'ERROR',
}
```

---

## Versioning

This package tracks the upstream
[`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)
minor version. The current release tracks upstream `3.2.0` and exposes the
full OSAMCommons surface — including the `isOnline()` reachability probe and
the `isDarkMode` / `applyComModStyles` dialog options added upstream in 3.2.0.

## License

MIT
