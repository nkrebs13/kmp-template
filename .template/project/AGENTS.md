# KMP Template: guide for coding agents

A Kotlin Multiplatform app: one Compose Multiplatform UI (`App()`) in `shared`, hosted by thin
platform apps. `CLAUDE.md` imports this file, so every agent follows the same rules. Run every
command from the repository root.

## Prerequisites

- **Java:** any JDK on `PATH` or in `JAVA_HOME` starts Gradle. Gradle downloads the JDK 21
  toolchain the build compiles with.
<!-- region desktop -->
  `desktopApp` compiles, runs and packages on JetBrains Runtime 21, also downloaded on first use.
<!-- endregion desktop -->
- **Android SDK:** `ANDROID_HOME`, or `sdk.dir` in `local.properties` (copy
  `local.properties.template`). Missing SDK = `SDK location not found`.
- **iOS:** macOS with Xcode 16 or newer, on Apple Silicon for simulator builds (there is no `iosX64`
  target, and x86_64 is excluded for the simulator). On other hosts Gradle skips the iOS targets.

## Modules

| Path | What it is |
|---|---|
| `shared/` | KMP library with the UI, logic and resources. Package `com.template.shared`. Source sets `commonMain`, `androidMain`, `iosMain`; tests in `commonTest`, `androidHostTest`, `iosTest`. |
<!-- region desktop -->
| `shared/src/jvmMain`, `jvmTest` | The desktop (JVM) source sets of `shared`. |
<!-- endregion desktop -->
| `androidApp/` | Android app: `MainActivity`, package and application ID `com.template.android`. |
| `iosApp/` | Xcode project: a SwiftUI shell (`iOSApp.swift`, `ContentView.swift`) that embeds the `shared` framework. Settings in `iosApp/Configuration/`. |
<!-- region desktop -->
| `desktopApp/` | Desktop (JVM) app: `main.kt` opens a window with `App()`. Package `com.template.desktop`. |
<!-- endregion desktop -->
| `baselineprofile/` | Generates the Android Baseline Profile (`com.android.test` module). |
| `build-logic/` | Included build with the convention plugins (`convention.*`) that hold all shared build configuration. |
| `config/` | `detekt/detekt.yml` (detekt + Compose rules) and `compose/stability.conf` (Compose compiler stability). |

Swift sees only the `shared` framework's public API. Entry points: `App()` in `commonMain`,
`MainViewController()` in `iosMain` (called by `ContentView.swift`), `MainActivity` in `androidApp`.
<!-- region desktop -->
Desktop: `main()` in `desktopApp/src/main/kotlin/com/template/desktop/main.kt`.
<!-- endregion desktop -->

## Verify: `./gradlew check`

`./gradlew check` is **the** verification command. In every module it runs Spotless (check only;
it never reformats), detekt, the unit tests of every target this host can build, Kover (at least
60% line coverage per KMP library module) and Android lint (`lintDebug`). On macOS that includes
the iOS simulator tests. Warnings are errors in detekt and Android lint.

`check` does not build the iOS app, package any app or run R8. Run these too when they apply:

```bash
./gradlew spotlessApply                          # fix formatting; run before check and before committing
./gradlew :shared:iosSimulatorArm64Test          # iOS tests only (macOS; already part of check there)
# The iOS app, as Xcode builds it (macOS). Also compiles the Swift code and embeds the framework.
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
<!-- region desktop -->
./gradlew :desktopApp:createDistributable        # desktop app image, as CI builds it
<!-- endregion desktop -->
./gradlew :androidApp:assembleRelease            # R8-minified release APK, as CI builds it
./gradlew verifyCatalog                          # every catalog coordinate is published (network)
```

CI (`.github/workflows/ci.yml`) runs these:

- Linux: `./gradlew spotlessCheck detekt`, then `./gradlew check :androidApp:assembleRelease :baselineprofile:assemble`
<!-- region desktop -->
  and `./gradlew :desktopApp:createDistributable`
<!-- endregion desktop -->
- macOS: `./gradlew :shared:iosSimulatorArm64Test :shared:linkDebugFrameworkIosSimulatorArm64`, then
  the `xcodebuild` above.
- Linux, as its own job on every event (and weekly): `./gradlew verifyCatalog`.

## Run the app

Each needs a device, a simulator or a GUI session.

Android (emulator running or device connected; `adb devices` lists it):

```bash
./gradlew :androidApp:installDebug
adb shell am start -n com.template.android/.MainActivity
```

iOS simulator (macOS). Use a UDID, not `booted`: several simulators may be booted.

```bash
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available                # pick an iPhone's UDID
xcrun simctl boot <UDID>                           # skip if it is already Booted
xcrun simctl install <UDID> build/xcode/Build/Products/Debug-iphonesimulator/iosApp.app
xcrun simctl launch <UDID> com.template.ios
xcrun simctl io <UDID> screenshot screen.png       # see the result
```

Or in Xcode: `open iosApp/iosApp.xcodeproj`, pick a simulator, Run. A device needs a team ID
(see "Where settings live").

<!-- region desktop -->
Desktop:

```bash
./gradlew :desktopApp:run                          # window
./gradlew :desktopApp:hotRun --auto                # window with Compose Hot Reload: saved edits appear live
```

Both need a GUI session. From SSH or a sandboxed shell they fail with `java.awt.HeadlessException`;
there, on macOS, build `:desktopApp:createDistributable` and launch it with
`open desktopApp/build/compose/binaries/main/app/KmpTemplate.app`.
<!-- endregion desktop -->

## Where settings live

Each setting has exactly one source. Change it there.

| Setting | File |
|---|---|
| Library and plugin versions | `gradle/libs.versions.toml`. Never write a version in a build file. |
| Android SDK levels | `gradle/libs.versions.toml` `[versions]`: `android-compile-sdk`, `android-target-sdk`, `android-min-sdk` |
| Android application ID | `app.applicationId` in `gradle.properties` |
| App version, Android | `app.versionCode`, `app.versionName` in `gradle.properties` |
<!-- region desktop -->
| App version, desktop | `app.versionName` in `gradle.properties`. The installer version is its leading `major.minor.patch` (`1.2.0-beta` packages as `1.2.0`), and major must be at least 1 for the macOS `.dmg`. |
| Desktop installer name | `app.packageName` in `gradle.properties` |
| Desktop Windows upgrade UUID | Derived from `app.applicationId`: changing the ID makes Windows treat the new `.msi` as a different app |
| Desktop window title | `desktopApp/src/main/kotlin/com/template/desktop/main.kt` |
<!-- endregion desktop -->
| Android app name | `androidApp/src/main/res/values/strings.xml` |
| Android locales offered in system settings | `androidApp/src/main/res/xml/locales_config.xml` |
| R8 keep rules | `androidApp/proguard-rules.pro` (libraries ship their own consumer rules) |
| App icons | Android: `androidApp/src/main/res/mipmap-*` and `drawable/ic_launcher_*`. iOS: one 1024×1024 PNG without alpha, `iosApp/iosApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. |
| iOS privacy manifest | `iosApp/iosApp/PrivacyInfo.xcprivacy`. Declare every tracking domain, collected data type and required-reason API that you or a dependency uses, or App Store Connect rejects the upload. |
| iOS display name, bundle ID, version, build number, deployment target (16.0), `TEAM_ID` | `iosApp/Configuration/Config.xcconfig` |
| A developer's own Apple team ID | `TEAM_ID` in `iosApp/Configuration/Local.xcconfig` (gitignored; copy `Local.xcconfig.example`) |
| Android release signing | `SIGNING_*` environment variables, or `signing.*` in `local.properties` (see Recipes) |
| JDK toolchain (21) and bytecode level (17) | `build-logic/convention/src/main/kotlin/convention/ProjectExtensions.kt` |
| detekt rules, Compose stability | `config/detekt/detekt.yml`, `config/compose/stability.conf` |
| Formatting (ktlint) | `.editorconfig` |
| Gradle flags (configuration cache, Isolated Projects) | `gradle.properties` |
| Dependency updates | `.github/dependabot.yml` |

The version lives in two files: `gradle.properties` for Gradle-built apps, `Config.xcconfig`
(`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) for iOS. Keep them equal.

## Recipes

**Add a dependency.** The catalog already lists optional libraries no module uses yet, between
`Optional: not referenced by the build` comments: Koin, Ktor (OkHttp and Darwin engines),
kotlinx serialization and datetime, Room with `sqlite-bundled`, DataStore, JetBrains lifecycle and
navigation, Coil 3, Tink, WorkManager, and the KSP, Room and serialization plugins. Reference the
alias in the source set that needs it, in the module's build file:

```kotlin
// shared/build.gradle.kts
plugins {
    id("convention.kmp.library")
    id("convention.compose")
    alias(libs.plugins.kotlin.serialization)          // a Gradle plugin: alias in plugins {}
}
kotlin {
    sourceSets {
        commonMain.dependencies { implementation(libs.kotlinx.serialization.json) }
        androidMain.dependencies { implementation(libs.ktor.client.okhttp) }
        iosMain.dependencies { implementation(libs.ktor.client.darwin) }
    }
}
```

A library not in the catalog: add a `[versions]` entry and a `[libraries]` (or `[plugins]`) entry
to `gradle/libs.versions.toml`, reference it as above, then run `./gradlew verifyCatalog`.

**Add a KMP module.** Create `<name>/build.gradle.kts`, add `include(":<name>")` to
`settings.gradle.kts`, and depend on it with `implementation(projects.<name>)`:

```kotlin
plugins {
    id("convention.kmp.library")
    // id("convention.compose")   // only if the module has Compose UI
}
kotlin {
    android { namespace = "com.template.<name>" }
    sourceSets {
        commonTest.dependencies { implementation(libs.kotlin.test) }
    }
}
```

Sources go in `<name>/src/commonMain/kotlin/com/template/<name>/`. The module needs tests from the
start: Kover fails `check` below 60% line coverage. Swift cannot see it directly; call it from `shared`.

**Add platform-specific code.** Declare `expect fun x(): T` in `commonMain`, then an `actual` in
each platform source set, in files named after the platform, like `Platform.kt` here:
`shared/src/commonMain/kotlin/com/template/shared/Platform.kt` (`expect fun getPlatformName()`),
`androidMain/.../Platform.android.kt`, `iosMain/.../Platform.ios.kt`.
<!-- region desktop -->
Desktop too: `jvmMain/.../Platform.jvm.kt`.
<!-- endregion desktop -->
A missing `actual` fails compilation of that target.

**Add a user-facing string.** Add `<string name="x">…</string>` to
`shared/src/commonMain/composeResources/values/strings.xml` and read it in a composable with
`stringResource(Res.string.x)`, importing `com.template.shared.generated.resources.Res` and
`com.template.shared.generated.resources.x`. `Res` is generated at build time and is internal to
`shared`.

**Add a test.** Use `kotlin.test` (`@Test`, `assertEquals`), never JUnit APIs. Put it in the
narrowest source set that can run it: `commonTest` runs on every target; a platform source set
(`androidHostTest`, `iosTest`) tests that platform's `actual`.
<!-- region desktop -->
`jvmTest` is the desktop one.
<!-- endregion desktop -->
Compose UI tests (`runComposeUiTest`) cannot go in `commonTest` as `@Test`: the Android host tests
have no Compose UI runtime. Write the body as a plain function in `commonTest` and call it from a
`@Test` in each platform test source set that has the runtime, as `AppUiTestBody.kt` and
`AppUiTest` do in `iosTest`.
<!-- region desktop -->
`jvmTest` has the runtime too, headless, so its UI tests also run on Linux.
<!-- endregion desktop -->
Wait for asynchronously loaded resources with `waitUntilExactlyOneExists` before asserting. After writing a UI test, break the string it asserts,
see it fail, then revert. Coroutine code: `runTest` from `kotlinx-coroutines-test` (already in
`commonTest`).

**Regenerate the baseline profile** after changing startup code:
`./gradlew :androidApp:generateBaselineProfile`. It boots the Gradle Managed Device `pixel6Api34`
(downloads an API 34 image on first use) and rewrites
`androidApp/src/release/generated/baselineProfiles/`; commit the result. The journeys it records
are in `baselineprofile/src/main/kotlin/com/template/baselineprofile/BaselineProfileGenerator.kt`.
To use a running emulator or device instead, set `useConnectedDevices = true` and remove
`managedDevices` in the `baselineProfile {}` block of `baselineprofile/build.gradle.kts`.

**Sign Android release builds.** Generate a keystore once:
`keytool -genkey -v -keystore release.jks -alias key0 -keyalg RSA -keysize 2048 -validity 10000`.
Then set all four of `SIGNING_STORE_FILE`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS`,
`SIGNING_KEY_PASSWORD` (CI), or all four of `signing.storeFile`, `signing.storePassword`,
`signing.keyAlias`, `signing.keyPassword` in `local.properties`. If any `SIGNING_*` variable is set,
`local.properties` is ignored. `./gradlew :androidApp:assembleRelease` (or `bundleRelease`) then
signs `androidApp/build/outputs/apk/release/androidApp-release.apk`. No values: unsigned release.
A partial set fails release packaging and names the missing keys. Never commit a keystore or password.

## Conventions

- **Logging:** `AppLogger` (Kermit), e.g. `AppLogger.i { "message" }`. Never `println`/`print`:
  `checkForbiddenCalls` (part of `check`) fails on them in production code. Tests may print.
- **No gate weakening:** no detekt baselines, no `@Suppress` without a comment saying why, no
  lowering Kover's minimum, no disabling lint checks to get green. Fix the code.
- **Zero new warnings** from Kotlin, detekt, lint or Xcode (except the accepted ones below).
- **detekt highlights:** max line 120, at most 2 `return`s per function, no magic numbers outside
  tests, no wildcard imports, no `TODO:`/`FIXME:` comments, no `TODO()` calls, functions at most 60
  lines. `@Composable` functions are PascalCase and take a `modifier: Modifier = Modifier`.
- **Formatting:** run `./gradlew spotlessApply` before committing; `check` only reports.
- **Build logic:** shared configuration belongs in a convention plugin in `build-logic/`. Isolated
  Projects is on: no `subprojects {}`/`allprojects {}`, and no build script may read or configure
  another project. Read Gradle and environment properties through `providers`.
- **iOS settings:** never edit `project.pbxproj` for settings; a value set there silently overrides
  the xcconfig. Never pick a team in Xcode's Signing & Capabilities tab (it writes your team into
  the project); use `Local.xcconfig`. Files under `iosApp/iosApp/` join the app target
  automatically (synchronized folder), so adding Swift files or resources needs no project edit.
  `Info.plist` must keep `CADisableMinimumFrameDurationOnPhone`; Compose aborts at launch without it.
  Keep `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64` in `Config.xcconfig`: `shared` has no Intel
  simulator target, and without it Xcode asks Gradle for one and fails.
- **No screenshot tests in `check`:** font rendering differs between macOS and Linux, so a
  screenshot that passes on one fails on the other, and `check` must be green on both.
- **Compose stability:** list your own immutable model types in `config/compose/stability.conf`
  (`com.template.model.*`, `//` comments). Compiler reports:
  `./gradlew -Pkmp.composeCompilerReports=true :shared:compileAndroidMain` writes
  `shared/build/compose-reports/` and `compose-metrics/`.

## Accepted warnings

These come from third-party tools. Leave them; don't spend time on them.

- Gradle: `Deprecated Gradle features were used in this build, making it incompatible with Gradle
  10.` It is detekt 1.23.8 calling `ReportingExtension.file` (shown with `--warning-mode all`).
  Also the notes `Isolated Projects is an incubating feature.` and `Type-safe project accessors is
  an incubating feature.`
- xcodebuild: `ld: warning: object file (…shared.framework/shared[…](libicu.icudtl_dat.o)) was built
  for newer 'iOS-simulator' version (18.5) than being linked (16.0)`. Skiko's prebuilt ICU data.
- xcodebuild: `appintentsmetadataprocessor … warning: Metadata extraction skipped. No
  AppIntents.framework dependency found.` Xcode prints it for every app without App Intents.
- xcodebuild: `note: Run script build phase 'Compile Kotlin Framework' will be run during every
  build`. Intended: Gradle does its own up-to-date checking.

## Definition of done

1. `./gradlew spotlessApply`, then `./gradlew check` passes.
2. On macOS, if you changed `shared/src/*Main` or `iosApp/`, the `xcodebuild` command above
   passes too.
3. New logic has tests, in the narrowest source set that can run it.
4. No new warnings, no weakened gates.
<!-- region desktop -->
5. If you changed `desktopApp/` or the desktop build logic, `./gradlew :desktopApp:createDistributable`
   passes too.
<!-- endregion desktop -->
