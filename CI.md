# CI Setup Plan

Notes for the planned CI work — to be implemented later.

CI provider: **GitHub Actions** (repo is already on GitHub).

Plan: ship all four pieces below (A + B + C + D). They're documented as
independent options so each can be added in its own PR if you want to
stage the rollout, but the end state is everything wired up.

For each: what it runs / how long / what it catches / cost and gotchas.

---

## A) JS-only checks

PR / push trigger, single ubuntu job:

```yaml
- checkout
- setup-node (Node 20)
- yarn install --immutable
- yarn typescript        # tsc --noEmit
- yarn test              # jest (existing __tests__/)
- yarn prepare           # bob build → produces lib/
```

- **Runtime**: ~1–2 min
- **What it catches**
  - TS type errors (`src/index.ts`, `src/types.ts`)
  - JS bridge unit-test regressions (`__tests__/index.test.ts`,
    `__tests__/linking-error.test.ts`)
  - `bob build` failures (any of the three targets — commonjs / module /
    typescript — failing). This step alone covers "can `lib/` be cleanly
    regenerated before publish?"
- **What it misses**: Android Kotlin compile, iOS podspec / Swift, example
  integration regressions
- **Maintenance cost**: near zero, pure Node, no cache headaches
- **Trigger**: `pull_request` + `push` on `main`

---

## B) A + Android library compile

Add a job (or a serial step) on top of A:

```yaml
- setup-java (Temurin 17)
- yarn install
- yarn prepare           # lib/ must exist before example links to it
- cd example/android && ./gradlew :react-native-modul-comu-osam:compileDebugKotlin
```

- **Runtime**: first run ~6–8 min (downloads gradle / RN / Kotlin
  toolchain), ~2–3 min with cache hits
- **What it catches (in addition to A)**
  - The `OSAMPackage.kt` RN-autolinking-regex trap (`@JvmOverloads` /
    default constructor args). When `findPackageClassName` fails to match,
    `compileDebugKotlin` errors with "Unresolved reference: cat".
  - Firebase `compileOnly` misconfiguration
  - `android/build.gradle` dep / minSdk / compileSdk drift
  - Source-incompatible upgrades (Kotlin 2.0.21, RN 0.79)
- **What it misses**: iOS, runtime behavior (compile only — no APK install,
  no emulator)
- **Maintenance cost**: medium
  - Needs `actions/cache` for `~/.gradle/caches` and `~/.gradle/wrapper`
    (otherwise every run is 6+ min)
  - Pin Gradle and JDK versions; occasional adjustment on RN bumps

---

## C) B + iOS example build

Add a macOS runner job on top of B:

```yaml
runs-on: macos-14
- setup-node + setup-ruby (bundler)
- yarn install
- yarn prepare
- cd example/ios && bundle install && bundle exec pod install
- xcodebuild -workspace Example.xcworkspace -scheme Example \
    -configuration Debug -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' build
```

- **Runtime**: ~10–15 min (macOS runner is slow + pod install + xcodebuild)
- **What it catches (in addition to B)**
  - podspec errors (deps, subspecs, min iOS version)
  - Swift files not registered in `project.pbxproj` (already burned us once
    per CLAUDE.md — `cannot find 'ClassName' in scope`)
  - `OSAMCommon` git tag fetch failure / Firebase pod conflicts
  - `GoogleService-Info.plist` / `config_keys.plist` registration issues
- **What it misses**: actual runtime behavior (no simulator boot, no app
  install)
- **Maintenance cost**: **high**
  - macOS runners are **~10x more expensive** than ubuntu (free for public
    repos, billed for private)
  - Xcode / iOS SDK / CocoaPods version drift regularly breaks `pod install`
    — pin versions explicitly
  - Pods caching is fiddly (`~/Library/Caches/CocoaPods` + `Pods/`)
  - `google-services.json` / `GoogleService-Info.plist` are gitignored —
    in CI either commit a placeholder plist (careful not to publish it) or
    store the real one as a base64 GitHub Secret and decode at runtime

---

## D) A + tag-triggered npm release

Add a separate workflow `release.yml`, triggered on `push: tags: ['v*']`:

```yaml
- checkout
- setup-node + registry-url: 'https://registry.npmjs.org'
- yarn install --immutable
- yarn typescript && yarn test
- yarn prepare
- npm publish --access public
  env:
    NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

- **Runtime**: ~2 min
- **Value**
  - Inverts the manual flow in `PUBLISHING.md` (`yarn prepare` → `npm pack`
    → `npm publish` → tag): developer just runs
    `npm version patch && git push --follow-tags`, CI publishes
  - Guarantees the npm tarball is built from a clean CI environment (no
    stale local `lib/`)
  - Optional: chain `gh release create` to auto-generate GitHub Release
    notes from CHANGELOG
- **Prerequisites**
  - Generate an **npm Automation token** (not a publish token — Automation
    bypasses 2FA), add to GitHub repo Secrets as `NPM_TOKEN`
  - Confirm `package.json#version` is driven by `npm version` (already the
    convention in `PUBLISHING.md`)
- **Maintenance cost**: very low; set-and-forget
- **Risk**: a wrong tag publishes immediately. Mitigations:
  - Add a `workflow_dispatch` confirmation input
  - Or restrict the trigger so the tag must be on `main`

---

## Implementation order

Suggested rollout (one PR per step):

1. **A** — fastest win, immediate quality gate on every PR
2. **D** — automate the publish step now that A's checks gate releases
3. **B** — adds Android coverage; needs gradle cache tuning
4. **C** — adds iOS coverage; needs macOS runner budget + Firebase plist
   strategy

After step 2 you already have ~95% of the practical regression coverage
(TS / Jest / bob build) plus automated publishing. B and C are higher-
investment, lower-frequency wins — ship them when you have time to iron
out the cache / runner / secrets issues without holding up other work.

---

## Combined implementation checklist

### Workflows

- [ ] `.github/workflows/ci.yml` — job `js` (Plan A: typescript + test +
      prepare)
- [ ] `.github/workflows/ci.yml` — job `android` (Plan B: gradle compile,
      with `actions/cache` for `~/.gradle/caches` and `~/.gradle/wrapper`)
- [ ] `.github/workflows/ci.yml` — job `ios` (Plan C: macos-14, pod install
      + xcodebuild Debug iphonesimulator, with caching for
      `~/Library/Caches/CocoaPods` and `example/ios/Pods`)
- [ ] `.github/workflows/release.yml` — Plan D, tag-triggered `npm publish`

### Secrets / repo config

- [ ] Generate npm Automation token, add as GitHub Secret `NPM_TOKEN`
- [ ] Decide on Firebase plist strategy for the iOS job:
      - Option 1: commit a placeholder `GoogleService-Info.plist` and
        ensure the example app builds without runtime Firebase init in CI
      - Option 2: store the real plist as `base64(GoogleService-Info.plist)`
        in `IOS_GOOGLE_SERVICES_PLIST` secret, decode in the workflow
- [ ] Same decision for Android `google-services.json` (mirror the iOS
      choice)
- [ ] (Optional) Branch protection rule on `main`: require the `js` job to
      pass before merge

### Docs

- [ ] Add CI status badge(s) to `README.md` and `README.ca.md`
- [ ] Update `PUBLISHING.md`: replace the manual `npm publish` step with
      `npm version <bump> && git push --follow-tags`; keep the
      `example-npm/` post-publish smoke test
- [ ] Mark the CI item in `CLAUDE.md`'s progress checklist as done once
      all four workflows are green

### Pinning / cache keys

- [ ] Pin Node version (Node 20)
- [ ] Pin JDK (Temurin 17) and Android SDK level for Plan B
- [ ] Pin Xcode version (`xcode-select`) and Ruby version for Plan C
- [ ] Cache keys: hash on `yarn.lock`, `example/yarn.lock`,
      `example/android/gradle/wrapper/gradle-wrapper.properties`,
      `example/ios/Podfile.lock`
