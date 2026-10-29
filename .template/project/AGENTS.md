# KMP Template: guide for coding agents

KMP Template is a Kotlin Multiplatform app. One Compose Multiplatform UI lives in `shared`; the
platform apps only host it. `CLAUDE.md` imports this file, so every agent reads the same rules.

## Prerequisites

- **Java:** any JDK on `PATH` or in `JAVA_HOME` starts Gradle; Gradle downloads the JDK 21 toolchain
  the build uses.
- **Android SDK:** `ANDROID_HOME`, or `sdk.dir` in `local.properties` (copy
  `local.properties.template`).
- **iOS:** macOS with Xcode 16 or newer; simulator builds and `iosSimulatorArm64Test` need an Apple
  Silicon Mac (no `iosX64` target, x86_64 excluded for the simulator). Elsewhere `check` skips the
  iOS targets.

## Definition of done

1. `./gradlew spotlessApply`, then `./gradlew check` passes. `check` runs Spotless, detekt, the
   unit tests of every target this machine can build, Kover (at least 60% line coverage of
   `shared`) and Android lint. Warnings are errors everywhere.
2. On macOS, if you touched `shared` or `iosApp`, `./gradlew :shared:iosSimulatorArm64Test` and the
   `xcodebuild` command below pass too. `check` skips iOS targets it cannot build.
3. New behavior has a test (`kotlin.test`, in the narrowest source set that can run it).

Never weaken a gate to get green: no detekt baselines, no `@Suppress` without a comment saying why,
no lowering the coverage minimum.

## Modules

- `shared/`: the KMP library with the UI (`App()`), logic and resources. Package
  `com.template.shared`. Source sets: `commonMain`, `androidMain`, `iosMain`, with tests in
  `commonTest`, `androidHostTest` and `iosTest`.
- `androidApp/`: the Android app (`MainActivity`), package `com.template.android`.
- `iosApp/`: the Xcode project, a SwiftUI shell that embeds the `shared` framework.
- `baselineprofile/`: generates the Android Baseline Profile.
<!-- region desktop -->
- `desktopApp/`: the desktop (JVM) app, package `com.template.desktop`. `shared` also has
  `jvmMain` and `jvmTest`.
<!-- endregion desktop -->
- `build-logic/`: convention plugins (`convention.*`) that hold all shared build configuration.
  Module build files only declare what is specific to them.
- `config/`: detekt rules (`config/detekt/detekt.yml`) and Compose stability
  (`config/compose/stability.conf`).

## Commands

```bash
./gradlew check                              # the verification gate (see above)
./gradlew spotlessApply                      # format Kotlin, Gradle and Markdown
./gradlew :shared:allTests                   # tests only
./gradlew :shared:iosSimulatorArm64Test      # iOS tests, macOS only
./gradlew verifyCatalog                      # every catalog coordinate resolves (network)
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
```

<!-- region desktop -->
Desktop:

```bash
./gradlew :desktopApp:createDistributable    # app image, as CI builds it
```
<!-- endregion desktop -->

Running the app needs a device, a simulator or a GUI session, so these are for a human or an agent
that has one:

```bash
./gradlew :androidApp:installDebug           # on a running emulator or connected device
open iosApp/iosApp.xcodeproj                 # then run from Xcode
```
<!-- region desktop -->
```bash
./gradlew :desktopApp:run                    # desktop window
./gradlew :desktopApp:hotRun --auto          # desktop window with Compose Hot Reload
```
<!-- endregion desktop -->

## Where settings live

- **Dependency and plugin versions, SDK levels:** `gradle/libs.versions.toml`. Never hardcode a
  version in a build file. The catalog also lists optional libraries that no module uses yet; to
  add one, reference its alias (`implementation(libs.<alias>)`).
- **App version:** `app.versionCode` and `app.versionName` in `gradle.properties`.
<!-- region desktop -->
- **Desktop installer name:** `app.packageName` in `gradle.properties`.
<!-- endregion desktop -->
- **iOS display name, bundle ID, versions, deployment target:** `iosApp/Configuration/Config.xcconfig`.
  Never edit `project.pbxproj` for settings: a pbxproj value silently overrides the xcconfig.
  A developer's team ID goes in the gitignored `iosApp/Configuration/Local.xcconfig`.
- **Android SDK path and release signing keys:** `local.properties` (gitignored; see
  `local.properties.template`), or `ANDROID_HOME` and `SIGNING_*` environment variables.
- **JDK:** toolchain 21 with Java 17 bytecode, set in `build-logic` (`ProjectExtensions.kt`).
- **Formatting rules:** `.editorconfig`.
- **CI:** `.github/workflows/ci.yml`. Dependency updates: `.github/dependabot.yml`.

## Conventions

- Log with `AppLogger` (Kermit). `println` is a detekt error.
- Platform code uses `expect`/`actual`: declare in `commonMain`, implement in every platform
  source set.
- A new module applies the convention plugins (`convention.kmp.library`, `convention.compose`, ...)
  rather than configuring Kotlin or Android itself.
- Files under `iosApp/iosApp/` join the Xcode target automatically (synchronized folder), so adding
  Swift files or resources needs no project edit.
- The committed baseline profile describes the original startup path. Regenerate it after changing
  startup code: `./gradlew :androidApp:generateBaselineProfile` (boots a Gradle Managed Device).
- Screenshot tests are not part of `check`: font rendering differs between macOS and Linux, so
  they would not pass on both.
