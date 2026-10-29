# KMP Template

A Kotlin Multiplatform app for Android and iOS, with one Compose Multiplatform UI in `shared`.
<!-- region desktop -->
It also runs as a desktop (JVM) app.
<!-- endregion desktop -->

Working with an AI coding agent? It should read [AGENTS.md](AGENTS.md) first.

## Prerequisites

- **JDK 21**, the build toolchain. The Gradle wrapper needs some Java runtime on `PATH` or
  `JAVA_HOME` to start; installing JDK 21 directly is simplest, otherwise Gradle downloads it.
- **Android SDK**: set `ANDROID_HOME`, or copy `local.properties.template` to `local.properties`
  and set `sdk.dir`.
- **Xcode 16 or newer** on macOS, for iOS. The app targets iOS 16+. Simulator builds need an Apple
  Silicon Mac: there is no `iosX64` target, and x86_64 is excluded for the simulator.

## Verify

```bash
./gradlew check            # formatting, static analysis, tests, coverage, Android lint
./gradlew spotlessApply    # fix formatting first; check never auto-corrects
```

## Android

```bash
./gradlew :androidApp:assembleDebug
./gradlew :androidApp:installDebug
adb shell am start -n com.template.android/.MainActivity
```

## iOS

App settings (display name, bundle ID, version, build number, deployment target) live in
`iosApp/Configuration/Config.xcconfig`. Change them there, not in Xcode's build settings editor.

To run on a device, set your Apple Developer team once (the file is gitignored):

```bash
cp iosApp/Configuration/Local.xcconfig.example iosApp/Configuration/Local.xcconfig
# then set TEAM_ID in Local.xcconfig (not in Xcode's Signing & Capabilities tab, which writes it
# into the project file)
```

In Xcode: open `iosApp/iosApp.xcodeproj`, pick a simulator or device, and run.

From the command line, on a simulator:

```bash
# Build for the simulator (also runs the Gradle phase that builds the shared framework)
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/xcode CODE_SIGNING_ALLOWED=NO build

# Boot a simulator, install, launch
xcrun simctl list devices available            # pick an iPhone
xcrun simctl boot "<device name or UDID>"
open -a Simulator
xcrun simctl install booted build/xcode/Build/Products/Debug-iphonesimulator/iosApp.app
xcrun simctl launch booted com.template.ios
```

<!-- region desktop -->
## Desktop

```bash
./gradlew :desktopApp:run                               # run the app
./gradlew :desktopApp:hotRun --auto                     # Compose Hot Reload: edits appear live
./gradlew :desktopApp:packageDistributionForCurrentOS   # .dmg on macOS, .msi on Windows, .deb on Linux
```

The desktop app builds and packages with JetBrains Runtime 21, which Gradle downloads on first use.
<!-- endregion desktop -->

## Release signing (Android)

To sign release builds, add your keystore details to `local.properties` (never commit this file):

```properties
signing.storeFile=/absolute/path/to/release.jks
signing.storePassword=your_store_password
signing.keyAlias=your_key_alias
signing.keyPassword=your_key_password
```

`signing.storeFile` is absolute, or relative to the repository root. The build signs the release
variant once all four values are set in one place; with none set, the release APK is unsigned.
Setting only some of them makes release packaging fail with a message naming the missing keys;
debug builds keep working.

Generate a keystore if you don't have one:

```bash
keytool -genkey -v -keystore release.jks -alias key0 -keyalg RSA -keysize 2048 -validity 10000
```

In CI, set `SIGNING_STORE_FILE`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_ALIAS` and
`SIGNING_KEY_PASSWORD` instead. If any of them is set, all four must be, and `local.properties`
is ignored.

## Baseline profiles

The `baselineprofile` module generates an
[Android Baseline Profile](https://developer.android.com/topic/performance/baselineprofiles/overview),
which pre-compiles the startup path so the app starts faster after install. The committed profile in
`androidApp/src/release/generated/baselineProfiles/` is packed into release builds. Regenerate it
after changing startup behavior (it boots a Gradle Managed Device by itself):

```bash
./gradlew :androidApp:generateBaselineProfile
```

## License

MIT; see [LICENSE](LICENSE).
