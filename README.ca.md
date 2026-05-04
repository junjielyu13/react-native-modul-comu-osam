# react-native-modul-comu-osam

> 📘 Also available in [English](./README.md).

Pont de React Native per al mòdul comú de l'Ajuntament de Barcelona — projecte
original: **[AjuntamentdeBarcelona/modul_comu_osam](https://github.com/AjuntamentdeBarcelona/modul_comu_osam)**
(Kotlin Multiplatform). Aquesta llibreria embolcalla l'API `OSAMCommons`
original un a un i l'exposa a React Native.

> **Important — registre del bundle ID / applicationId.** El backend d'OSAM
> només respon a les aplicacions el bundle identifier de les quals (iOS) /
> applicationId (Android) estigui prèviament registrat al servidor. Abans
> de publicar, **confirmeu l'identificador amb l'equip d'OSAM** perquè el
> puguin donar d'alta — en cas contrari, totes les crides a
> `versionControl` / `rating` / events de cicle de vida retornaran
> `status: "ERROR"`. L'identificador utilitzat al llarg d'aquest repositori
> (`cat.bcn.parkguell.altech`) és **només un exemple** — és el registrat
> per a l'app de demostració de Park Güell, no un valor que hàgiu de
> reutilitzar.

Exposa les deu operacions de `OSAMCommons` a JavaScript amb els mateixos
noms de mètode que la llibreria original:

| Mètode | Retorna | Valors d'estat |
|---|---|---|
| `versionControl(languageCode, isDarkMode?, applyComModStyles?)` | `{ status }` | `ACCEPTED` · `DISMISSED` · `CANCELLED` · `ERROR` |
| `rating(languageCode, isDarkMode?, applyComModStyles?)` | `{ status }` | `ACCEPTED` · `DISMISSED` · `ERROR` |
| `deviceInformation()` | `{ platformName, platformVersion, platformModel }` | — |
| `appInformation()` | `{ appName, appVersionName, appVersionCode }` | — |
| `changeLanguageEvent(languageCode)` | `{ status }` | `SUCCESS` · `UNCHANGED` · `ERROR` |
| `firstTimeOrUpdateEvent(languageCode)` | `{ status }` | `SUCCESS` · `UNCHANGED` · `ERROR` |
| `subscribeToCustomTopic(topic)` | `{ status }` | `ACCEPTED` · `ERROR` |
| `unsubscribeToCustomTopic(topic)` | `{ status }` | `ACCEPTED` · `ERROR` |
| `getFCMToken()` | `{ token }` | rebutja en cas d'error |
| `isOnline()` | `{ online }` | `true` · `false` (mai rebutja) |

Codis d'idioma admesos: `ca` · `es` · `en`.

`versionControl` i `rating` accepten dos booleans opcionals afegits a la
3.2.0 original: `isDarkMode` (per defecte `false`) i `applyComModStyles`
(per defecte `true`).

## Instal·lació

```sh
yarn add react-native-modul-comu-osam
# o
npm install react-native-modul-comu-osam
```

La llibreria incorpora **wrappers per defecte basats en Firebase**
(Crashlytics, Performance, Analytics, Messaging). Les aplicacions
consumidores han de:

1. Proporcionar Firebase i un endpoint de backend via
   `config_keys.{xml,plist}` (detallat més avall), **O**
2. Substituir-los per una implementació pròpia dels wrappers
   ([Substituir els wrappers per defecte](#substituir-els-wrappers-per-defecte)).

---

## Configuració iOS

### 1. Podfile

`OSAMCommon` no es troba a CocoaPods trunk — declareu-lo des del repositori
git original, i forceu l'enllaçament estàtic (Firebase el recomana, i
OSAMCommon es distribueix com a framework estàtic):

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

Després instal·leu:

```sh
cd ios && bundle install && bundle exec pod install
```

El podspec incorpora automàticament `FirebaseAnalytics` /
`FirebaseCrashlytics` / `FirebasePerformance` / `FirebaseMessaging`.

### 2. Configuració de Firebase

Col·loqueu `GoogleService-Info.plist` dins el target de l'app i assegureu-vos
que apareix a *Build Phases → Copy Bundle Resources*. Arrossegar i deixar-lo
al navegador d'Xcode ho fa automàticament.

### 3. Endpoint del backend (`config_keys.plist`)

Creeu `config_keys.plist` al target de l'app amb una clau
`common_module_endpoint`:

```xml
<!-- ios/<YourApp>/config_keys.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>common_module_endpoint</key>
  <string>https://el-vostre-backend-osam.exemple.com</string>
</dict>
</plist>
```

Igual que `GoogleService-Info.plist`, assegureu-vos que estigui inclòs a
*Copy Bundle Resources*.

### 4. `AppDelegate.swift`

```swift
import FirebaseCore
import react_native_modul_comu_osam

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: …) -> Bool {
  FirebaseApp.configure()
  OSAMConfiguration.wrappersProvider = DefaultOSAMWrappersProvider()

  // …inicia RN…
}
```

> Preferiu codificar l'endpoint en lloc de llegir `config_keys.plist`?
> Passeu-lo al constructor:
> `DefaultOSAMWrappersProvider(backendEndpoint: "https://…")`.

### 5. Notificacions push (necessari per a les funcions de FCM)

Els mètodes de FCM (`getFCMToken`, `subscribeToCustomTopic`,
`unsubscribeToCustomTopic`) només funcionen després que iOS hagi obtingut
un **token d'APNS** i l'hagi passat a Firebase Messaging. Sense això,
`getFCMToken` rebutja amb `No APNS token specified before fetching FCM
token` i les subscripcions a tòpics fallen silenciosament. Aquest
requisit és exclusiu d'iOS — el camí d'FCM d'Android no passa per APNS.

Podeu ometre aquesta secció si només feu servir mètodes no relacionats
amb FCM (`versionControl` / `rating` / `deviceInformation` /
`appInformation` / `changeLanguageEvent` / `firstTimeOrUpdateEvent`) o si
heu substituït `OSAMWrappersProvider` per una implementació que no faci
servir FCM.

**a. Capabilities d'Xcode.** Obriu el vostre `.xcworkspace`, seleccioneu
el target de l'app → *Signing & Capabilities*:

- `+ Capability` → **Push Notifications** (genera
  `<YourApp>.entitlements` amb `aps-environment = development`).
- `+ Capability` → **Background Modes** → marqueu **Remote notifications**.
- A *Signing*, trieu un Team (necessari perquè els entitlements de push
  tinguin efecte).

**b. Consola de Firebase.** Pugeu una clau d'autenticació d'APNs (`.p8`)
per al vostre bundle ID a *Project Settings → Cloud Messaging → Apple app
configuration*. Sense ella, els tokens d'APNS s'obtenen però Firebase no
els pot intercanviar per tokens d'FCM.

**c. Amplieu `AppDelegate.swift`** per sol·licitar el permís, registrar-vos
a APNS i reenviar el token del dispositiu a Firebase:

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
    // …inicia RN…
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

**d. Entorn de prova.** Els simuladors d'iOS **< 16** no poden obtenir
tokens d'APNS — feu servir un simulador d'iOS 16+ o un dispositiu físic.
El registre d'APNS és asíncron, doneu-li un segon o dos després de
l'arrencada abans de cridar `getFCMToken` / `subscribeToCustomTopic`.

---

## Configuració Android

### 1. JitPack

La llibreria obté `common-android` (l'artefacte d'OSAM) via JitPack.
Afegiu el repositori a `settings.gradle` (o al `build.gradle` de l'arrel):

```gradle
allprojects {
  repositories {
    maven { url "https://jitpack.io" }
  }
}
```

`OSAMPackage` és detectat pel sistema d'autolinking de React Native — no
cal registrar-lo manualment.

### 2. Plugins i dependències de Firebase

Les dependències de Firebase de la llibreria són `compileOnly`, per tant
l'aplicació consumidora les ha de subministrar en temps d'execució.

`build.gradle` del projecte:

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

### 3. Configuració de Firebase

Col·loqueu `google-services.json` a `android/app/`.

### 4. Endpoint del backend (`config_keys.xml`)

Creeu `android/app/src/main/res/values/config_keys.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <string name="common_module_endpoint" translatable="false">https://el-vostre-backend-osam.exemple.com</string>
</resources>
```

La llibreria cerca el recurs pel **nom** (`common_module_endpoint`), no
pel nom del fitxer — qualsevol `res/values/*.xml` amb aquesta entrada
`<string>` funciona. `config_keys.xml` és la ubicació recomanada per
mantenir simetria amb iOS i separar les claus de configuració dels
textos d'interfície. `translatable="false"` avisa al lint d'Android que
és una constant de configuració.

### 5. `Application.onCreate`

Establiu la factoria de wrappers **abans** de `SoLoader.init`:

```kotlin
import cat.bcn.osam.reactnative.DefaultOSAMWrappersFactory
import cat.bcn.osam.reactnative.OSAMConfiguration

override fun onCreate() {
  super.onCreate()
  OSAMConfiguration.wrappersFactory = DefaultOSAMWrappersFactory()
  SoLoader.init(this, OpenSourceMergedSoMapping)
}
```

> Preferiu codificar l'endpoint en lloc de llegir `config_keys.xml`?
> Passeu-lo al constructor:
> `DefaultOSAMWrappersFactory(backendEndpoint = "https://…")`.

---

## Ús

```ts
import OSAMModule, { OSAMResultEnum } from 'react-native-modul-comu-osam';

// Diàleg d'actualització forçada / recomanada.
const { status } = await OSAMModule.versionControl('ca');
if (status === OSAMResultEnum.ACCEPTED) { /* l'usuari s'ha actualitzat */ }

// …o amb les opcions de diàleg de la 3.2.0 (posicionals):
await OSAMModule.versionControl(
  'ca',
  true,  // isDarkMode — opcional, per defecte false
  true,  // applyComModStyles — opcional, per defecte true
);
await OSAMModule.rating('ca', true, false);

// Sol·licitud periòdica de valoració.
await OSAMModule.rating('ca');

// Metadades del dispositiu / app.
const device = await OSAMModule.deviceInformation();
const app = await OSAMModule.appInformation();

// Events d'idioma / cicle de vida (crida'ls a l'arrencada de l'app i
// quan l'usuari canviï d'idioma).
await OSAMModule.firstTimeOrUpdateEvent('ca');
await OSAMModule.changeLanguageEvent('es');

// FCM.
await OSAMModule.subscribeToCustomTopic('park-guell-news');
await OSAMModule.unsubscribeToCustomTopic('park-guell-news');
const { token } = await OSAMModule.getFCMToken();

// Comprovació de connectivitat (afegit a la 3.2.0). Resol amb
// `{ online }` — mai rebutja, així que es pot cridar sense try/catch.
const { online } = await OSAMModule.isOnline();
```

---

## Substituir els wrappers per defecte

Els cinc wrappers (`Crashlytics`, `Performance`, `Analytics`,
`PlatformUtil`, `Messaging`) són substituïbles. Feu servir aquest camí
quan no vulgueu Firebase, o quan vulgueu redirigir les analítiques / els
informes d'errors a un altre SDK. Les interfícies `OSAMWrappers` /
`OSAMWrappersProvider` que cal implementar estan descrites a
`android/src/main/java/cat/bcn/osam/reactnative/OSAMWrappers.kt` i
`ios/OSAMWrappersProvider.swift`.

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
    backendEndpoint = "https://el-vostre-backend.exemple.com",
  )
}

override fun onCreate() {
  super.onCreate()
  OSAMConfiguration.wrappersFactory = MyWrappersFactory()
  SoLoader.init(this, OpenSourceMergedSoMapping)
}
```

Si no establiu cap factoria personalitzada, s'utilitza
`DefaultOSAMWrappersFactory` (basada en Firebase). La factoria per defecte
només resol les classes de Firebase quan realment s'instancia, de manera
que una aplicació consumidora que **sempre** instal·li una factoria
personalitzada pot ometre Firebase completament.

### iOS

```swift
import react_native_modul_comu_osam

class MyProvider: NSObject, OSAMWrappersProvider {
  var backendEndpoint: String { "https://el-vostre-backend.exemple.com" }
  func makeCrashlyticsWrapper() -> CrashlyticsWrapper { MyCrashlytics() }
  func makePerformanceWrapper() -> PerformanceWrapper { MyPerformance() }
  func makeAnalyticsWrapper() -> AnalyticsWrapper { MyAnalytics() }
  func makePlatformUtil() -> PlatformUtil { MyPlatformUtil() }
  func makeMessagingWrapper() -> MessagingWrapper { MyMessaging() }
}

OSAMConfiguration.wrappersProvider = MyProvider()
```

> ⚠️ A iOS els pods de Firebase s'enllacen sempre perquè estan declarats
> de manera incondicional al podspec. Substituir el provider atura la
> seva execució, però no elimina el binari. Per eliminar-los
> completament, cal bifurcar el podspec.

---

## Apps d'exemple

S'inclouen dues apps de proves bàsiques (smoke-test), totes dues
exercitant els deu mètodes contra el backend de desenvolupament real
d'OSAM:

- [`example/`](./example/README.md) — consumeix la llibreria directament
  des d'aquest workspace (`portal:..`). Feu-la servir per al
  **desenvolupament de la llibreria** — les edicions a `src/` /
  `android/` / `ios/` es veuen de manera immediata.
- [`example-npm/`](./example-npm/README.md) — consumeix la llibreria des
  del **paquet publicat a npm**. Feu-la servir com a **prova abans/després
  de publicar** per verificar que el tarball pujat a npm realment funciona.

Totes dues apps tenen `cat.bcn.parkguell.altech` codificat com a bundle
ID / applicationId, perquè és l'identificador que reconeix el backend de
desenvolupament compartit. **Aquesta és l'elecció d'aquest exemple, no
un valor reutilitzable** — per a la vostra app, consulteu la nota de la
part superior d'aquest fitxer sobre registrar el vostre identificador
amb l'equip d'OSAM.

Els fitxers de configuració de Firebase (`google-services.json` /
`GoogleService-Info.plist`) estan ignorats al git — heu de col·locar-hi
els vostres propis, corresponents al bundle ID que realment penseu fer
servir.

---

## API

```ts
interface OSAMModuleInterface {
  versionControl(
    languageCode: 'ca' | 'es' | 'en' | string,
    isDarkMode?: boolean,        // per defecte: false
    applyComModStyles?: boolean, // per defecte: true
  ): Promise<{ status: string }>;
  rating(
    languageCode: 'ca' | 'es' | 'en' | string,
    isDarkMode?: boolean,        // per defecte: false
    applyComModStyles?: boolean, // per defecte: true
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

## Versionat

Aquest paquet segueix la versió menor del projecte original
[`modul_comu_osam`](https://github.com/AjuntamentdeBarcelona/modul_comu_osam).
La versió actual segueix la `3.2.0` original i exposa tota la superfície
d'OSAMCommons — incloent-hi la comprovació de connectivitat `isOnline()` i
les opcions de diàleg `isDarkMode` / `applyComModStyles` afegides a la 3.2.0.

## Llicència

MIT
