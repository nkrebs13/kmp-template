# KMP Template

A Kotlin Multiplatform app for Android and iOS, with one Compose Multiplatform UI in `shared`.
<!-- region desktop -->
It also runs as a desktop (JVM) app.
<!-- endregion desktop -->

[AGENTS.md](AGENTS.md) is the full guide: module map, where every setting lives, recipes and
conventions. Coding agents read it automatically; humans will find it useful too.

## Prerequisites

- A JDK on `PATH` or in `JAVA_HOME` to start Gradle. The build downloads the JDK 21 toolchain it
  needs.
- The Android SDK: set `ANDROID_HOME`, or copy `local.properties.template` to `local.properties`
  and set `sdk.dir`.
- macOS with Xcode 16 or newer, for iOS; simulator builds need an Apple Silicon Mac. The app
  targets iOS 16+.

## Verify

```bash
./gradlew spotlessApply    # format; check never reformats
./gradlew check            # formatting, static analysis, tests, coverage, Android lint
```

## Run

Android, on an emulator or a connected device:

```bash
./gradlew :androidApp:installDebug
adb shell am start -n com.template.android/.MainActivity
```

iOS: open `iosApp/iosApp.xcodeproj` in Xcode, pick a simulator and run. To run on a device, set
your Apple Developer team once, in a file git ignores:

```bash
cp iosApp/Configuration/Local.xcconfig.example iosApp/Configuration/Local.xcconfig
# set TEAM_ID in Local.xcconfig, not in Xcode's Signing & Capabilities tab
```

The display name, bundle ID, version and deployment target live in
`iosApp/Configuration/Config.xcconfig`; change them there, not in Xcode's build settings editor.
AGENTS.md also shows how to build and launch on a simulator from the command line.

<!-- region desktop -->
Desktop:

```bash
./gradlew :desktopApp:run                               # run
./gradlew :desktopApp:hotRun --auto                     # run with Compose Hot Reload: edits appear live
./gradlew :desktopApp:packageDistributionForCurrentOS   # .dmg on macOS, .msi on Windows, .deb on Linux
```
<!-- endregion desktop -->

## Release signing (Android)

Generate a keystore once, and keep it out of git:

```bash
keytool -genkey -v -keystore release.jks -alias key0 -keyalg RSA -keysize 2048 -validity 10000
```

Then add the four values to `local.properties` (gitignored):

```properties
signing.storeFile=/absolute/path/to/release.jks
signing.storePassword=your_store_password
signing.keyAlias=key0
signing.keyPassword=your_key_password
```

In CI, set `SIGNING_STORE_FILE`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS` and
`SIGNING_KEY_PASSWORD` instead; if any of them is set, `local.properties` is ignored.
`./gradlew :androidApp:assembleRelease` then signs the release APK. With nothing set the release
build is unsigned, and a partial set fails release packaging with a message naming what is missing.

## Baseline profile

`androidApp/src/release/generated/baselineProfiles/` holds an
[Android Baseline Profile](https://developer.android.com/topic/performance/baselineprofiles/overview)
that makes startup faster after install. Regenerate it after changing startup code; it boots a
Gradle Managed Device by itself:

```bash
./gradlew :androidApp:generateBaselineProfile
```

## License

MIT; see [LICENSE](LICENSE).
