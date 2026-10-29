# KMP Template — Claude Code Maintainer Guide

## Project Philosophy

This is a **skeleton template**, not a demo app. It provides production-grade build infrastructure
and a clean starting point for new KMP projects. It intentionally contains no sample app features,
no DI framework, no networking, no navigation — those are the user's choices to make.

**Do not add sample features.** Every dependency and line of code a user must delete is friction.

## Critical Rule: Zero Claude Code Files in Generated Projects

`setup.sh` deletes `.claude/` entirely during generation (it is in `.template/template-only.txt`),
and both `setup.sh` itself and `template.yml` assert it is gone. Never modify setup.sh to preserve
Claude Code files in generated output. Generated projects get a tool-neutral `AGENTS.md` and a root
`CLAUDE.md` containing only `@AGENTS.md`, both from `.template/project/`.

Generated projects must have exactly **zero** `.claude/` files.

## Project Structure

```
kmp-template/
├── shared/              # KMP shared module (commonMain/androidMain/iosMain)
├── androidApp/          # Android application
├── iosApp/              # iOS Xcode project (Swift + Compose bridge)
├── desktopApp/          # Desktop (JVM) application (convention.jvm.application)
├── baselineprofile/     # Baseline Profile producer (com.android.test, Gradle Managed Device)
├── build-logic/         # Included build: convention plugins (convention.*) + verifyCatalog
├── config/
│   ├── compose/stability.conf   # Compose compiler stability config (`//` comments)
│   └── detekt/detekt.yml        # detekt + Compose rules config
├── .template/           # Generator data (template-only): manifest.env, template-only.txt,
│                        #   forbidden*.txt, check-leftovers.sh, rewrite.pl, project/ (generated docs)
├── tests/setup/run.sh   # setup.sh test harness (plain bash)
├── docs/                # Documentation
├── gradle/              # Version catalog (libs.versions.toml), gradle-daemon-jvm.properties
├── setup.sh             # Template generation script
└── .github/workflows/   # ci.yml (project CI), template.yml + template-cleanup.yml (template-only)
```

Convention plugins (`build-logic/convention/src/main/kotlin/convention/`):
`convention.kmp.library`, `convention.compose`, `convention.android.application`,
`convention.quality` (applied by the others), `convention.root` (root only: `check`, root-level
Spotless, `verifyCatalog`). The root `build.gradle.kts` holds only `apply false` lines.
SDK levels come from the catalog `[versions]` (`android-compile-sdk` etc.); the app version from
`gradle.properties` (`app.versionCode`, `app.versionName`); JDK toolchain 21 and Java 17 bytecode
from the constants in `ProjectExtensions.kt`. ktlint settings live in `.editorconfig`.

## Build Commands

```bash
# Full local gate (run before every PR). `check` runs in every project:
# spotlessCheck, detekt, :shared:allTests, :shared:koverVerify, :androidApp:lintDebug
./gradlew check :androidApp:assembleDebug :shared:linkDebugFrameworkIosSimulatorArm64

# Desktop app
./gradlew :desktopApp:run                    # needs a GUI session (HeadlessException over plain SSH)
./gradlew :desktopApp:hotRun --auto          # Compose Hot Reload (bundled with the CMP plugin)
./gradlew :desktopApp:packageDistributionForCurrentOS   # .dmg / .msi / .deb

# Auto-fix formatting (nothing auto-corrects during check)
./gradlew spotlessApply

# Prove every catalog coordinate exists, incl. unreferenced optional entries (network; not in check)
./gradlew verifyCatalog

# Individual checks
./gradlew detekt                      # per module, config/detekt/detekt.yml
./gradlew :shared:allTests
./gradlew :shared:iosSimulatorArm64Test   # includes the Compose UI test (macOS only)
./gradlew :shared:koverVerify         # 60% line coverage minimum
./gradlew :androidApp:lintDebug       # Warnings are errors

# Compose compiler reports/metrics -> <module>/build/compose-reports, compose-metrics
./gradlew -Pkmp.composeCompilerReports=true :shared:compileAndroidMain
```

## Desktop Notes

- `region desktop` / `endregion desktop` comment lines (`//`, `#` or `<!-- -->`) mark desktop-only
  blocks: `include(":desktopApp")`, the `jvm()` target in `KmpLibraryConventionPlugin`, the `jvmTest`
  dependencies in `shared/build.gradle.kts`, `app.packageName` in `gradle.properties`, the CI desktop
  step and the desktop parts of `.template/project/*.md`. `--no-desktop` deletes those blocks and the
  `DESKTOP_PATHS` from `manifest.env` (`desktopApp/`, `shared/src/jvmMain`, `shared/src/jvmTest`), and
  renames the CI job to "Android". The default generation keeps the markers. The `kotlin-jvm` catalog
  entry and its root `apply false` stay either way: `convention.jvm.application` needs them.
- `hotRun` comes from the Compose Multiplatform plugin's bundled Compose Hot Reload (it runs on JetBrains Runtime, which the toolchain resolver provisioned in testing); it attaches to
  `kotlin("jvm")` modules, so no `org.jetbrains.compose.hot-reload` plugin is applied explicitly.
- CI builds `:desktopApp:createDistributable` (jpackage app image), not installers, which would need
  dpkg/fakeroot on the runner and add nothing to the check.
- `desktopApp`'s toolchain is JetBrains Runtime 21 (`convention.jvm.application`), downloaded by the
  foojay resolver on first use. Compose packaging rejects Homebrew's JDK (compose-multiplatform#3107)
  and Hot Reload works best on JBR, so pinning the vendor makes both behave the same on every machine.
- The installer name comes from `app.packageName` in `gradle.properties` (lowercased for Deb);
  the installer version is the leading `major.minor.patch` of `app.versionName` (`1.2.0-beta` packages as
  `1.2.0`, so ship pre-release installers under a lower patch: Windows won't upgrade between equal
  versions), and the Windows upgrade UUID derives from `app.applicationId`. The window title is a literal
  in `main.kt`.

## iOS Notes

- **`iosApp/Configuration/Config.xcconfig` is the source of truth** for the display name, bundle ID,
  marketing/build version, deployment target (16.0), `TEAM_ID`/`DEVELOPMENT_TEAM`, simulator
  `EXCLUDED_ARCHS` and `ENABLE_USER_SCRIPT_SANDBOXING = NO`. `Debug.xcconfig`/`Release.xcconfig` include it
  plus the gitignored `Local.xcconfig` (per-developer team ID). **Never edit `project.pbxproj` for
  settings**: a pbxproj target setting silently overrides the xcconfig. Each setting has exactly one source.
- The app group is an Xcode 16 synchronized folder (objectVersion 77): files under `iosApp/iosApp/` join the
  target automatically, so adding Swift files or resources needs no pbxproj edit. `Info.plist` is the one
  membership exception. The entry point is `iOSApp.swift` (`struct iOSApp`), a fixed name the generator
  never renames.
- `Info.plist` must keep `CADisableMinimumFrameDurationOnPhone = true`; Compose aborts at launch without it.
- The "Compile Kotlin Framework" phase runs `embedAndSignAppleFrameworkForXcode` with `alwaysOutOfDate = 1`
  (Gradle checks up-to-dateness), so it declares no inputs/outputs. Xcode prints a `note:` about it running
  every build; that is expected.
- Build (CI runs this in the `ios` job, with the shared `iosApp` scheme):
  ```bash
  xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
  ```
- Known remaining build output (third-party, not ours): an `ld: warning` that skiko's `libicu.icudtl_dat.o`
  was built for iOS 18.5 (newer than our 16.0 target), and `appintentsmetadataprocessor` "Metadata
  extraction skipped", which Xcode prints for every app without App Intents.

## Template Generation Test

```bash
# Generator checks (seconds; no Gradle). On macOS run the harness with /bin/bash (3.2) too.
shellcheck setup.sh .template/*.sh tests/setup/*.sh
bash tests/setup/run.sh && /bin/bash tests/setup/run.sh

# Full e2e: generate from the committed HEAD in a scratch dir, then build it
git clone -q . /tmp/e2e-test && cp -R .template /tmp/e2e-template && cd /tmp/e2e-test
/bin/bash setup.sh --name WeatherApp --package com.acme.weather --author "Test" --yes --json
bash /tmp/e2e-template/check-leftovers.sh .        # setup.sh already ran it; must print nothing
./gradlew check :desktopApp:createDistributable
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
# --no-desktop: same, with --no-desktop, then ./gradlew check
```

## Key Design Decisions

- **`.template/` is the single source of truth** for generation, and is deleted by it:
  `manifest.env` (tokens, sourced by bash), `template-only.txt` (deleted paths), `forbidden*.txt`
  (leftover regexes), `check-leftovers.sh`, `rewrite.pl`, and `project/` (the generated README,
  AGENTS.md, CLAUDE.md). A file that mentions a token needs no setup.sh change; a new template-only
  file goes in `template-only.txt`.
- **Tokens**: `KmpTemplate` (name: rootProject, logger tag, installer), `KMP Template` (display
  name: Android label, iOS display name, window title), `com.template.android` (app package),
  `com.template.<module>` (`<package>.<module>`), `com.template.ios` (bundle ID). The sentinel stayed
  `com.template` rather than moving to a new one: the leftover check and validation (packages inside
  `com.template` are rejected) give the safety uniqueness would, without moving every source file.
  Replacement is one literal pass, longest token first (`rewrite.pl`), so replaced text is never
  re-replaced; Kotlin sources move by a generic `find` over `*/kotlin/com/template/**`.
- **setup.sh CLI** is flag-driven and agent-safe: it prompts only when stdin is a TTY and a required
  value is missing, needs `--yes` without a TTY, and `--json` prints exactly one object on stdout.
  Exit codes: 2 usage, 3 invalid value, 4 precondition (dirty tree, already initialized, no perl/git),
  5 internal (prints recovery commands). bash 3.2 compatible: CI runs it on macOS `/bin/bash`.
- **Atomicity**: validate and plan first (`--dry-run` stops there); refuse a dirty tree; back up to
  `$TMPDIR` when there is no `.git`; run the leftover check before touching git; only then a new
  history on `main` with one commit (`--keep-git`, `--no-commit` change that).
- **Leftover check masking**: a user value that itself matches a forbidden pattern (author
  `nkrebs13`, repo `kmp-template`) is masked before matching, so it does not count as a leftover.
- **LICENSE**: MIT, holder from `--author`, else `git config user.name`, else the GitHub owner.
- **`template-cleanup.yml`** initializes "Use this template" repositories on their first push via
  `--derive-from-github owner/repo` (name: PascalCase repo; package `io.github.<owner>.<repo>`
  sanitized; bundle ID sanitized separately since it allows `-` but not `_`). If `GITHUB_TOKEN` may
  not push the workflow-file deletions, it restores them, pushes the rest and opens an issue listing
  them. Every template-only workflow is guarded on the repository name, so leftovers stay inert.
- **iOS renaming touches only `iosApp/Configuration/Config.xcconfig`** (bundle ID, display name); setup.sh
  never edits Swift files or the pbxproj
- **The committed baseline profile** is renamed with the rest, but its Compose lambda hashes depend on
  the package, so generated projects should regenerate it (their AGENTS.md says so)
- **`config/compose/stability.conf`** lists only read-only collection interfaces and `kotlin.time.*`,
  not `kotlin.collections.*`; it is a tracked compile input (editing it recompiles)
- **Detekt**: 1.23.8 until 2.x ships stable; `warningsAsErrors: true`, `checkExhaustiveness: true`
  (so every Compose rule is listed in detekt.yml), `maxIssues: 0`
- **Isolated Projects** on (`org.gradle.unsafe.isolated-projects=true`; the name without `unsafe.` is ignored)
- **Kover**: 60% line coverage on `shared` module
- **Android lint**: `warningsAsErrors = true` (aborting on errors is AGP's default)

## CI Minutes Status

CI_MINUTES: AVAILABLE (public repo). `ci.yml` runs Static analysis + Android on ubuntu and iOS on
`macos-26`; `template.yml` runs the generator lint/tests and a generation matrix on ubuntu and
`macos-26`. Both run on pull requests targeting `main` and pushes to `main` (`template.yml` only in
`nkrebs13/kmp-template`); `ci.yml` also runs weekly, and its `verifyCatalog` job checks every catalog
coordinate. Local verification is still preferred during iteration; the PR run is authoritative.

## Version Tags

Tags v2.0.0, v2.1.0, v2.2.0, v3.0.0, v3.1.0 exist on the remote. CHANGELOG comparison links depend on them.
