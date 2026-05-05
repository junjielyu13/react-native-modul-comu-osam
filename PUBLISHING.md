# Publishing `react-native-modul-comu-osam` to npm

Step-by-step release checklist for cutting a new version of the library.
The package is public and unscoped on the npm registry. Tag format is
`v<version>` (the podspec resolves `:tag => "v#{s.version}"` from
`package.json`, so this is load-bearing — don't change it).

---

## Branching model

`main` exists **only** to carry tagged release commits and to publish from.
`dev` is the integration branch — it must always be in a shippable state.

- **Never commit directly to `main` or `dev`.** Both are protected and
  require PRs (`.github/CODEOWNERS` enforces admin review).
- **`main`**: release tags + `npm publish` only. No day-to-day work, no
  chores, no docs commits, no direct feature merges. The only commits
  here are merge commits coming in from `dev` via release PRs.
- **`dev`**: must always represent complete, tested, shippable code. No
  half-finished features, no WIP commits, no standalone `chore:` commits.
  Doc / chore / CI changes still go through their own branch + PR.
- **All work** happens on dedicated branches that PR into `dev`:
  - `feat/<name>` — new feature or upstream bump
  - `fix/<name>` — bug fix
  - `hotfix/<name>` — urgent fix on top of a tagged release
  - `release/<vX.Y.Z>` — release-prep (version bump, CHANGELOG entry,
    README / podspec / gradle adjustments)

A release flows:
`release/<vX.Y.Z>` → PR → `dev` → PR → `main` → tag + `npm publish`.

The `npm publish` and `git tag` steps below run **from `main`**, never
from `dev` or a release branch.

---

## 0. Prerequisites (one-time setup)

- Be a maintainer on the npm package `react-native-modul-comu-osam`.
- Be logged in to npm:
  ```sh
  npm whoami            # should print your npm username
  npm login             # if not logged in
  ```
- Push access to `github.com/junjielyu13/react-native-modul-comu-osam`.

---

## 1. Decide the new version

Follow [SemVer](https://semver.org/) and the upstream OSAM mapping in
the README's *Versioning* section:

- **Major** — breaking change to the JS API surface.
- **Minor** — new method, new optional param, or upstream OSAM minor bump
  (e.g. 3.1.0 → 3.2.0 was 0.2.x → 0.3.0).
- **Patch** — bug fix, doc-only change, or podspec/gradle metadata fix.

Write the version down — you'll use it in steps 2, 4, 6, and 7. The rest
of this guide uses `<NEW>` as a placeholder (e.g. `0.3.0`).

---

## 2. Update version metadata on a `release/<vX.Y.Z>` branch

```sh
git checkout dev && git pull origin dev
git checkout -b release/v<NEW>
```

Edit these files in one commit:

| File | Change |
|---|---|
| `package.json` | `"version": "<NEW>"` |
| `example-npm/package.json` | `"react-native-modul-comu-osam": "^<NEW>"` |
| `example-npm/README.md` | Update the `^<OLD>` reference in the intro paragraph |
| `CLAUDE.md` | Update the `^<OLD>` reference in the example-npm section |
| `CHANGELOG.md` | Add a `## [<NEW>] — <YYYY-MM-DD>` entry above the previous one, plus a tag link at the bottom |
| `README.md` | Add a row to the *Versioning* table |
| `README.ca.md` | Add the same row to the *Versionat* table |

`react-native-modul-comu-osam.podspec` and `android/build.gradle` already
read versions dynamically — the podspec from `package.json["version"]`,
gradle from the `osamCommonVersion` ext property — so there's nothing to
edit there unless the upstream OSAM version itself changes.

If the upstream OSAM version changed, also bump:
- `android/build.gradle` — `safeExtGet('osamCommonVersion', '<NEW_OSAM>')`
- `react-native-modul-comu-osam.podspec` — `s.dependency "OSAMCommon", "~> <NEW_OSAM>"`
- `README.md` / `README.ca.md` — Podfile snippet `:tag => '<NEW_OSAM>'`
- Both example apps' Podfile if they pin the tag.

Commit with `chore(release): bump library to <NEW> (OSAM <UPSTREAM>)`.

---

## 3. Merge `release/v<NEW>` → `dev` → `main`

```sh
git push -u origin release/v<NEW>
```

Then open two PRs (web UI or `gh pr create`):

1. `release/v<NEW>` → `dev` — gets reviewed, CI passes, merged.
2. `dev` → `main` — release PR. Title `Release v<NEW> (OSAM <UPSTREAM>)`,
   body summarising the CHANGELOG entry. Merge once approved.

Both branches are protected; `.github/CODEOWNERS` requires admin review.

After step 3 you should be on `main` with the version-bump commit at HEAD:

```sh
git checkout main && git pull origin main
git log -1 --oneline                  # should show the release merge
```

All remaining steps run **from `main`**. Don't publish from `dev` or a
release branch — `main` is the only source of truth for tagged releases.

---

## 4. Build `lib/`

`react-native-builder-bob` emits `lib/{commonjs,module,typescript}` —
these are listed in `package.json#files` so they ship in the tarball,
but they're gitignored locally.

```sh
yarn prepare
```

Verify the three targets exist:

```sh
ls lib/commonjs lib/module lib/typescript
```

If any are empty, the publish will ship a broken package. Don't skip this.

---

## 5. Smoke-test before publishing

Either:

- **Option A — local example.** From `example/`, run `yarn android` and
  `yarn ios` and click through the 10 buttons. This consumes the library
  via the `react-native.config.js` workspace bridge that points at the
  repo root, so Metro / autolinking pick up your local `src/` directly,
  not `lib/`. (See CLAUDE.md *Gotchas* for why `portal:..` / `link:..`
  don't work under yarn berry's `nodeLinker: node-modules`.)
- **Option B — pack-and-install dry run.** Build the actual tarball and
  inspect/install it without publishing:
  ```sh
  npm pack                                # writes react-native-modul-comu-osam-<NEW>.tgz
  tar -tzf react-native-modul-comu-osam-<NEW>.tgz | head -40
  # confirm src/, lib/, android/, ios/, the .podspec, package.json, CHANGELOG.md are present
  ```
  You can also `npm install ../react-native-modul-comu-osam/react-native-modul-comu-osam-<NEW>.tgz`
  in a scratch app to install exactly what would be published.

Option B is what catches missing `files` entries / stale `lib/` builds —
the same class of bug `example-npm/` exists to catch *post*-publish.
Highly recommended for non-patch releases.

---

## 6. Publish to npm

You must be on `main` with the release merge commit at HEAD (see step 3).

```sh
git rev-parse --abbrev-ref HEAD       # must print "main"
npm publish
```

The package is public and unscoped, so no `--access public` flag is
needed. If 2FA is enabled on the npm account, you'll be prompted for an
OTP — re-run with `npm publish --otp=<6-digit-code>`.

Verify:

```sh
npm view react-native-modul-comu-osam version    # should print <NEW>
npm view react-native-modul-comu-osam dist-tags  # latest = <NEW>
```

> ⚠️ **You can't unpublish freely.** npm only allows `npm unpublish`
> within 72h of publish, and only if no other package depends on it.
> If you publish a broken version, the right move is to publish a patch
> immediately — don't try to overwrite.

---

## 7. Tag the release on GitHub

The CHANGELOG already references the tag link (e.g.
`https://github.com/junjielyu13/react-native-modul-comu-osam/releases/tag/v<NEW>`)
— you just need to actually create the tag and push it.

```sh
git tag -a v<NEW> -m "Release v<NEW>"
git push origin v<NEW>
```

Then on GitHub, draft a release from that tag — paste the relevant
section of `CHANGELOG.md` as the release notes.

---

## 8. Validate the published tarball with `example-npm/`

`example-npm/` exists specifically to verify the *published* package is
complete:

```sh
cd example-npm
rm -rf node_modules                   # nuke installed deps
: > yarn.lock                         # truncate (don't delete!) — yarn berry
                                      # treats example-npm as an independent
                                      # project only if a yarn.lock exists.
                                      # Empty file = "re-resolve from registry".
yarn install                          # pulls react-native-modul-comu-osam@^<NEW> from npm
yarn android                          # or: cd ios && bundle exec pod install && cd .. && yarn ios
```

> ⚠️ Don't `rm -rf yarn.lock` — without the empty sentinel file yarn
> berry refuses to install with "doesn't seem to be part of the project".
> See CLAUDE.md *Gotchas* for the full backstory.

If `yarn install` resolves to the wrong version, check that `npm view` in
step 6 actually shows `<NEW>` as `latest` — it can take a few seconds for
the registry CDN to update.

Quick check that the resolved version matches what was just published:

```sh
node -p "require('react-native-modul-comu-osam/package.json').version"
# should print <NEW>
```

> Day-to-day library development should keep using `example/` (live
> workspace link). `example-npm/` is the smoke test for "is the tarball
> on npm actually usable."

---

## Quick reference (TL;DR)

```sh
# 1. cut a release branch off dev
git checkout dev && git pull origin dev
git checkout -b release/v<NEW>

# 2. edit package.json, example-npm/package.json, CHANGELOG.md, READMEs
git commit -am "chore(release): bump library to <NEW> (OSAM <UPSTREAM>)"
git push -u origin release/v<NEW>

# 3. open PRs: release/v<NEW> -> dev, then dev -> main. Merge both.

# 4. switch to main and build
git checkout main && git pull origin main
yarn prepare

# 5. (recommended) inspect the would-be tarball
npm pack && tar -tzf react-native-modul-comu-osam-<NEW>.tgz | head

# 6. publish
npm publish                                   # prompts for OTP if 2FA on

# 7. tag
git tag -a v<NEW> -m "Release v<NEW>"
git push origin v<NEW>

# 8. validate the tarball post-publish
cd example-npm && rm -rf node_modules && : > yarn.lock && yarn install && yarn android
```

---

## Common gotchas

- **Always publish from `main`.** `dev` and release branches must never
  ship to npm — `main` is the only branch whose HEAD corresponds to a
  tagged published version. Step 6's `git rev-parse --abbrev-ref HEAD`
  check exists for this reason.
- **`yarn prepare` MUST run before `npm publish`.** `lib/` is gitignored
  and not regenerated by `npm publish` itself. If `lib/` is stale or
  missing, the published package's `main` / `module` / `types` entries
  point at nothing and consumers see "module not found" at import time.
  (`npm publish` does run `prepare` automatically as a lifecycle hook,
  but running it explicitly first lets you inspect the output.)
- **Tag format is `v<version>`, not `<version>`.** The podspec uses
  `:tag => "v#{s.version}"`, so a bare `0.3.0` tag breaks `pod install`
  for any consumer pinning the library by `:git`/`:tag`.
- **Don't run `npm publish` from a dirty tree.** The tarball is built
  from the working directory, so uncommitted edits ship to npm. Always
  commit + merge first, *then* publish.
- **Don't `rm -rf yarn.lock` in `example-npm/`.** Yarn berry uses the
  presence of an (empty) `yarn.lock` as the marker that the directory
  is an independent project and not part of the root. Use `: > yarn.lock`
  to truncate, never `rm`. Same applies to `example/`.
- **Don't add `"packageManager": "yarn@3.6.4"` to the root `package.json`.**
  See CLAUDE.md — it breaks `yarn install` inside the example apps.
- **`example-npm/` won't pick up the new version until npm has it.** It
  resolves `^<NEW>` from the public registry, not from the local
  workspace. Reproduce-before-publish belongs to step 5 (Option B), not
  step 8.
- **Bump the upstream OSAM tag in BOTH places** (gradle + podspec) when
  the upstream version changes — drift between Android and iOS is silent
  and the example app may build green on one platform while the other
  pulls a stale OSAM artifact.
