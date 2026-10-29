# KMP Template — Claude Code Maintainer Guide

## Project Philosophy

This is a **skeleton template**, not a demo app. It provides production-grade build infrastructure
and a clean starting point for new KMP projects. It intentionally contains no sample app features,
no DI framework, no networking, no navigation — those are the user's choices to make.

**Do not add sample features.** Every dependency and line of code a user must delete is friction.

## Critical Rule: Zero Claude Code Files in Generated Projects

`setup.sh` deletes `.claude/` entirely during generation. CI enforces this with a hard assertion.
Never modify setup.sh to preserve Claude Code files in generated output.

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
├── scripts/             # Utility scripts (validate.sh)
├── docs/                # Documentation
├── gradle/              # Version catalog (libs.versions.toml), gradle-daemon-jvm.properties
├── setup.sh             # Template generation script
└── .github/workflows/     # ci.yml (project CI), template.yml (template-only)
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

- The `// region desktop` markers cover exactly two Gradle lines: `include(":desktopApp")` in
  `settings.gradle.kts` and the `jvm()` target in `KmpLibraryConventionPlugin`. Everything else
  (`desktopApp/`, `shared/src/jvmMain`, `jvmTest`, the `kotlin-jvm` catalog and root plugin lines, CI,
  setup.sh, docs) is removed by the generator by path, not by markers.
- `hotRun` comes from the Compose Multiplatform plugin's bundled Compose Hot Reload (it runs on JetBrains Runtime, which the toolchain resolver provisioned in testing); it attaches to
  `kotlin("jvm")` modules, so no `org.jetbrains.compose.hot-reload` plugin is applied explicitly.
- CI builds `:desktopApp:createDistributable` (jpackage app image), not installers, which would need
  dpkg/fakeroot on the runner and add nothing to the check.
- Packaging with a Homebrew JDK fails `checkRuntime` (compose-multiplatform#3107). Use a Temurin/Corretto/JBR
  toolchain, or pass `-Pcompose.desktop.packaging.checkJdkVendor=false` on a machine that has only Homebrew.
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
# Full e2e test — generates a project, verifies no artifacts, verifies it builds
cp -r . /tmp/e2e-test && cd /tmp/e2e-test
printf 'WeatherApp\ncom.example.weather\ncom.example.weather\ny\n' | bash setup.sh
grep -ri "com.template\|TemplateApp\|KmpTemplate\|orgName" . --exclude-dir=.git | wc -l  # Must be 0
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
test ! -d ".claude" && echo "PASS" || echo "FAIL"
./gradlew :shared:allTests :androidApp:assembleDebug
cd - && rm -rf /tmp/e2e-test
```

## Key Design Decisions

- **`replace_in_directory`** excludes `.git/`, `build/`, `.gradle/`, `node_modules/` and handles
  `.kt`, `.kts`, `.xml`, `.gradle`, `.toml`, `.conf`, `.sh`, `.md`, `.swift`, `.plist`, `.pbxproj`
- **iOS renaming touches only `iosApp/Configuration/Config.xcconfig`** (bundle ID, display name); setup.sh
  never edits Swift files or the pbxproj
- **Git reinit**: setup.sh always runs `rm -rf .git && git init` for a clean history
- **`__PROJECT_NAME__`** placeholder in `docs/README_TEMPLATE.md` — avoids overbroad "Template" replacement
- **`config/compose/stability.conf`** lists only read-only collection interfaces and `kotlin.time.*`,
  not `kotlin.collections.*`; it is a tracked compile input (editing it recompiles)
- **Detekt**: 1.23.8 until 2.x ships stable; `warningsAsErrors: true`, `checkExhaustiveness: true`
  (so every Compose rule is listed in detekt.yml), `maxIssues: 0`
- **Isolated Projects** on (`org.gradle.unsafe.isolated-projects=true`; the name without `unsafe.` is ignored)
- **Kover**: 60% line coverage on `shared` module
- **Android lint**: `warningsAsErrors = true` (aborting on errors is AGP's default)

## CI Minutes Status

CI_MINUTES: AVAILABLE (public repo). `ci.yml` runs Static analysis + Android on ubuntu and iOS on
`macos-26`; `template.yml` runs Template Generation on `macos-26`. Both run on pull requests
targeting `main` and pushes to `main` (`template.yml` only in `nkrebs13/kmp-template`); `ci.yml` also
runs weekly, and its `verifyCatalog` job checks every catalog coordinate. Local verification is still
preferred during iteration; the PR run is authoritative.

## Version Tags

Tags v2.0.0, v2.1.0, v2.2.0, v3.0.0, v3.1.0 exist on the remote. CHANGELOG comparison links depend on them.
