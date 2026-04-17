# react-native-modul-comu-osam

React Native bridge for the Barcelona City Council common module
([`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)).

Exposes the four OSAMCommons operations to JavaScript:

- `checkVersionControl(languageCode)` — the force-update / recommended-update dialog
- `showRatingDialog(languageCode)` — the native rating prompt
- `getDeviceInformation()` — platform name / version / model
- `getAppInformation()` — app name / versionName / versionCode

## Installation

```sh
yarn add react-native-modul-comu-osam
# or
npm install react-native-modul-comu-osam
```

### iOS

The podspec depends on `OSAMCommon` plus Firebase Analytics / Crashlytics /
Performance / Messaging for the default wrappers. `OSAMCommon` isn't on
CocoaPods trunk, so it must be declared explicitly in the consumer `Podfile`:

```ruby
target 'YourApp' do
  pod 'OSAMCommon',
    :git => 'https://github.com/AjuntamentdeBarcelona/modul_comu_osam.git',
    :tag => '3.1.0'

  use_frameworks! :linkage => :static
  $RNFirebaseAsStaticFramework = true

  # …use_react_native!…
end
```

Then install:

```sh
cd ios && bundle install && bundle exec pod install
```

### Android

The library declares the `common-android` artifact via JitPack. Add JitPack to
the project-level `settings.gradle` (or `build.gradle`):

```gradle
allprojects {
  repositories {
    maven { url "https://jitpack.io" }
  }
}
```

`OSAMPackage` is picked up by React Native autolinking — no manual package
registration is needed. The default wrappers read the backend endpoint from
a string resource:

```xml
<!-- android/app/src/main/res/values/strings.xml -->
<string name="common_module_endpoint">https://your-osam-backend.example.com</string>
```

On iOS, place the same endpoint in `config_keys.plist` under the key
`common_module_endpoint`, or supply it explicitly (see below).

## Usage

```ts
import OSAMModule, { OSAMResultEnum } from 'react-native-modul-comu-osam';

const { status } = await OSAMModule.checkVersionControl('en');
if (status === OSAMResultEnum.ACCEPTED) { /* user updated */ }

const device = await OSAMModule.getDeviceInformation();
const app = await OSAMModule.getAppInformation();
```

## Overriding the default wrappers

The library ships Firebase-backed wrappers by default, but all five wrappers
(`Crashlytics`, `Performance`, `Analytics`, `PlatformUtil`, `Messaging`) are
pluggable.

### Android

Assign a custom `OSAMWrappersFactory` to `OSAMConfiguration.wrappersFactory`
**before** `SoLoader.init` runs — typically the first line of
`Application.onCreate`:

```kotlin
import cat.bcn.osam.reactnative.OSAMConfiguration

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

To reuse the Firebase defaults but override the endpoint only:

```kotlin
OSAMConfiguration.wrappersFactory =
  DefaultOSAMWrappersFactory(backendEndpoint = "https://…")
```

### iOS

Assign a custom `OSAMWrappersProvider` to `OSAMConfiguration.wrappersProvider`
**before** the first call — typically in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:

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

> Note: on iOS the Firebase pods are always linked because they're declared in
> the podspec. Overriding the provider avoids running the Firebase wrappers but
> does not drop the dependencies. To remove them entirely, fork the podspec.

## API

```ts
interface OSAMModuleInterface {
  checkVersionControl(languageCode: 'ca' | 'es' | 'en' | string):
    Promise<{ status: string; description?: string }>;
  showRatingDialog(languageCode: 'ca' | 'es' | 'en' | string):
    Promise<{ status: string; description?: string }>;
  getDeviceInformation():
    Promise<{ platformName: string; platformVersion: string; platformModel: string }>;
  getAppInformation():
    Promise<{ appName: string; appVersionName: string; appVersionCode: string }>;
}

enum OSAMResultEnum {
  CANCELLED = 'CANCELLED',
  DISMISS = 'DISMISS',
  ACCEPTED = 'ACCEPTED',
  ERROR = 'ERROR',
}
```

## Versioning

This package tracks the upstream `modul_comu_osam` minor version. `0.1.0` is
based on upstream `3.1.0`.

## License

MIT
